class Config {
  // Supabase 配置
  static const String supabaseUrl = 'https://your-project-ref.supabase.co';
  static const String supabaseAnonKey = 'your_supabase_anon_key';
  static const String supabaseGreenhouse = 'east-suburb-farm';

  // 华为云 IAM 鉴权配置
  static const String iamAuthUrl = 'https://iam.cn-north-4.myhuaweicloud.com/v3/auth/tokens';
  static const String iamUser = 'your_iam_username';
  static const String iamPassword = 'your_iam_password';
  static const String iamDomain = 'your_iam_domain';
  static const String iamProject = 'cn-north-4';

  // 华为云 IoTDA 设备控制配置
  static const String iotCommandUrl = 'https://{endpoint}/v5/iot/{project_id}/devices/{device_id}/commands';
  static const String iotInstanceId = 'your_instance_id';
  static const String iotServiceId = 'smartFarm';

  // 本地 AMQP 转发 WebSocket 服务地址
  static const String webSocketUrl = 'ws://192.168.x.x:8083';
}
