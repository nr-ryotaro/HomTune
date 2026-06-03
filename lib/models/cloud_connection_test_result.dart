class CloudConnectionTestResult {
  final bool success;
  final String modelId;
  final String message;

  const CloudConnectionTestResult({
    required this.success,
    required this.modelId,
    required this.message,
  });
}