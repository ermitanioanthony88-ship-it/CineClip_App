import 'video_export_contract.dart';
import 'video_export_native.dart'
    if (dart.library.js_interop) 'video_export_web.dart' as implementation;

export 'video_export_contract.dart';

VideoExporter createVideoExportService() =>
    implementation.createVideoExportService();
