class Config {
  // Supabase 配置
  static const String supabaseUrl = 'https://your-project-ref.supabase.co';
  static const String supabaseAnonKey = 'your_supabase_anon_key';
  static const String supabaseServiceRoleKey = 'sb_secret_xxxxxxxxxxxxxxxxxxxxxxxx';
  static const String supabaseGreenhouse = 'east-suburb-farm';

  // EMQX MQTT 服务器配置
  static const String emqxHost = 'your_emqx_server_ip';
  static const int emqxPort = 1883;
  static const String emqxClientId = 'smart_farm_flutter_app';

  // MQTT Topic 定义
  static const String topicReport = 'smart_farm/report';
  static const String topicCommand = 'smart_farm/command';
  static const String topicResponse = 'smart_farm/response';
  static const String topicStatus = 'smart_farm/status';

  // 高德地图 API 配置
  static const String amapWeatherUrl = "https://restapi.amap.com/v3/weather/weatherInfo";
  static const String amapAuthKey = "xxxxxxxxxxxxxxxxxxxxxxxxxxxx";

  // 扣子 (Coze) AI 平台配置
  static const String cozeApiUrl = 'https://api.coze.cn/v3/chat';
  static const String cozeApiToken = 'pat_xxxxxxxxxxxxxxxxxxxxxxxxxxxx';
  static const String cozeBotId = 'xxxxxxxxxxxxxxxxxxxxx';

  // 语音识别 (百度ASR / 可替换任意STT服务) 配置
  // 留空则禁用语音输入功能
  static const String sttApiUrl = 'https://vop.baidu.com/server_api';
  static const String sttApiKey = 'your_baidu_asr_api_key';
}
