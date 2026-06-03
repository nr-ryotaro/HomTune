import '../../models/device.dart';
import '../../models/room.dart';
import '../sources/device_local_source.dart';
import '../sources/device_seed_source.dart';

/// デバイス永続化とシードデータ合成。
class DeviceRepository {
  DeviceRepository({
    DeviceLocalSource? localSource,
    DeviceSeedSource? seedSource,
  })  : _local = localSource ?? DeviceLocalSource(),
        _seed = seedSource ?? DeviceSeedSource();

  final DeviceLocalSource _local;
  final DeviceSeedSource _seed;

  bool isSeedDevice(String id) => _local.isSeedDevice(id);

  Set<String> get seedDeviceIds => DeviceLocalSource.seedDeviceIds;

  Future<void> persistUserDevices(List<Device> allDevices) async {
    final userDevices =
        allDevices.where((d) => !isSeedDevice(d.id)).toList();
    await _local.saveUserDevices(userDevices);
  }

  Future<List<Device>> loadPersistedUserDevices() =>
      _local.loadUserDevices();

  /// persisted + in-memory ユーザーデバイスを ID でマージ。
  List<Device> mergeUserDevices({
    required List<Device> persisted,
    required List<Device> inMemory,
  }) {
    final userById = <String, Device>{};
    for (final d in persisted) {
      userById[d.id] = d;
    }
    for (final d in inMemory) {
      if (!isSeedDevice(d.id)) {
        userById[d.id] = d;
      }
    }
    return userById.values.toList();
  }

  Future<List<Device>> applySeedDevices(
    List<Device> devices,
    List<Room> rooms,
  ) =>
      _seed.mergeSeedDevices(devices, rooms);
}
