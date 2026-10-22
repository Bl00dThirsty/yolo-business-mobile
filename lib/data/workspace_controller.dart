import 'dart:async';
import 'package:flutter/foundation.dart';
import 'business_repository.dart';
import 'models.dart';

class WorkspaceController extends ChangeNotifier {
  final BusinessRepository repository;
  WorkspaceController(this.repository);
  List<PickupSite> sites = [];
  List<Delivery> deliveries = [];
  PickupSite? site;
  bool loading = true, isAdmin = false, pending = false;
  String? error;
  DateTime? updatedAt;
  Timer? _timer;
  int _generation = 0, _request = 0;
  bool _disposed = false;
  Future<void> initialize() async {
    final generation = ++_generation;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final workspace = await repository.workspace();
      final saved = await repository.readPending();
      if (_disposed || generation != _generation) return;
      sites = (workspace['locations'] as List)
          .map((e) => PickupSite(Json.from(e)))
          .toList();
      isAdmin = workspace['is_admin'] == true;
      pending = saved != null;
      final id = saved?['payload']?['location_id'] ?? site?.id;
      site = sites.where((s) => s.id == id).firstOrNull ?? sites.firstOrNull;
      deliveries = [];
      updatedAt = null;
      await refresh();
      if (!_disposed && generation == _generation) resume();
    } catch (e) {
      if (!_disposed && generation == _generation) {
        error = friendlyError(e);
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> selectSite(PickupSite next) async {
    if (_disposed || (pending && next.id != site?.id)) return;
    ++_generation;
    site = next;
    deliveries = [];
    updatedAt = null;
    loading = true;
    error = null;
    notifyListeners();
    await refresh();
  }

  Future<void> refresh() async {
    final generation = _generation, request = ++_request, id = site?.id;
    if (id == null) {
      loading = false;
      if (!_disposed) notifyListeners();
      return;
    }
    try {
      final rows = await repository.deliveries(id);
      if (_disposed || generation != _generation || request != _request) return;
      deliveries = rows;
      updatedAt = DateTime.now();
      error = null;
    } catch (e) {
      if (_disposed || generation != _generation || request != _request) return;
      error =
          'Actualisation impossible. Les informations affichées peuvent être anciennes.';
    }
    loading = false;
    notifyListeners();
  }

  Future<void> checkPending() async {
    pending = await repository.readPending() != null;
    if (!_disposed) notifyListeners();
  }

  void pause() {
    _timer?.cancel();
  }

  void resume() {
    if (_disposed) return;
    pause();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => refresh());
  }

  @override
  void dispose() {
    _disposed = true;
    ++_generation;
    pause();
    super.dispose();
  }
}
