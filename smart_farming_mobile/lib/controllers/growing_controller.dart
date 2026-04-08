import '../services/growing_service.dart';
import 'base_controller.dart';

class GrowingController extends BaseController {
  final GrowingService _service;

  GrowingController(this._service);

  List<Map<String, dynamic>> activities = <Map<String, dynamic>>[];
  Map<String, dynamic> harvestSummary = <String, dynamic>{};

  Future<void> loadActivities() async {
    setLoading(true);
    clearMessages();

    final activitiesResult = await _service.fetchActivities();
    final harvestResult = await _service.fetchHarvestSummary();

    if (activitiesResult.isSuccess) {
      activities = activitiesResult.data ?? <Map<String, dynamic>>[];
    } else {
      setError(activitiesResult.error ?? 'Failed to load activities');
    }

    if (harvestResult.isSuccess) {
      harvestSummary = harvestResult.data ?? <String, dynamic>{};
    }

    setLoading(false);
  }

  Future<void> completeTask(String activityId, int taskIndex) async {
    final result = await _service.completeTask(
      activityId: activityId,
      taskIndex: taskIndex,
    );
    if (result.isSuccess) {
      setSuccess('Task marked complete');
      await loadActivities();
    } else {
      setError(result.error ?? 'Could not complete task');
    }
  }

  Future<void> updateNotes(String activityId, String notes) async {
    final result = await _service.updateActivity(
      activityId: activityId,
      notes: notes,
    );
    if (result.isSuccess) {
      setSuccess('Activity updated');
      await loadActivities();
    } else {
      setError(result.error ?? 'Could not update activity');
    }
  }

  Future<void> deleteActivity(String activityId) async {
    final result = await _service.deleteActivity(activityId);
    if (result.isSuccess) {
      setSuccess('Activity deleted');
      await loadActivities();
    } else {
      setError(result.error ?? 'Delete failed');
    }
  }

  Future<void> saveExpense(Map<String, dynamic> payload) async {
    final result = await _service.saveExpense(payload);
    if (result.isSuccess) {
      setSuccess('Expense saved');
    } else {
      setError(result.error ?? 'Failed to save expense');
    }
  }
}
