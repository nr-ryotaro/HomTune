from pathlib import Path

lines = Path('lib/models/device.dart').read_text(encoding='utf-8').splitlines()
models = Path('lib/models')


def write(name: str, header: str, slice_lines: list[str]) -> None:
    (models / name).write_text(header + '\n'.join(slice_lines) + '\n', encoding='utf-8')


write('device_enums.dart', '', lines[3:6])
write('device_maintenance.dart', '', lines[294:440])
write('device_manual.dart', "import 'device_enums.dart';\n\n", lines[441:493])
write('device_warranty.dart', '', lines[494:633])
write('device_asset.dart', '', lines[634:743])

device_header = """import 'safety_info.dart';
import 'maintenance_task.dart';
import 'device_enums.dart';
import 'device_maintenance.dart';
import 'device_manual.dart';
import 'device_warranty.dart';
import 'device_asset.dart';

export 'device_enums.dart';
export 'device_maintenance.dart';
export 'device_manual.dart';
export 'device_warranty.dart';
export 'device_asset.dart';

"""
write('device.dart', device_header, lines[7:293])
print('split ok')
