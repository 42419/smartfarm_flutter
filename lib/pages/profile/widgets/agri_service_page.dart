import 'package:flutter/material.dart';

class AgriServicePage extends StatelessWidget {
  const AgriServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: const Text(
          '农业服务',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildServiceCard(
            context: context,
            icon: Icons.psychology_outlined,
            iconColor: Colors.purpleAccent,
            title: 'AI 病害诊断',
            subtitle: '拍照识别作物病害，获取防治方案',
            tag: '智能识别',
          ),
          const SizedBox(height: 12),
          _buildServiceCard(
            context: context,
            icon: Icons.person_outline,
            iconColor: Colors.blueAccent,
            title: '专家在线咨询',
            subtitle: '农业专家一对一解答种植难题',
            tag: '30分钟内响应',
          ),
          const SizedBox(height: 12),
          _buildServiceCard(
            context: context,
            icon: Icons.science_outlined,
            iconColor: Colors.green,
            title: '土壤检测服务',
            subtitle: '送检土壤样本，获取完整养分分析报告',
            tag: '7日出报告',
          ),
          const SizedBox(height: 12),
          _buildServiceCard(
            context: context,
            icon: Icons.auto_graph,
            iconColor: Colors.orangeAccent,
            title: '种植方案定制',
            subtitle: '基于大棚环境数据，生成个性化种植方案',
            tag: 'AI 生成',
          ),
          const SizedBox(height: 12),
          _buildServiceCard(
            context: context,
            icon: Icons.trending_up,
            iconColor: Colors.redAccent,
            title: '产量预测分析',
            subtitle: '结合历史数据与当前长势，预测当季产量',
            tag: '精准预测',
          ),
          const SizedBox(height: 16),
          Text(
            '常见问题',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _buildFaqItem(
            context: context,
            question: '如何判断作物是否缺乏氮元素？',
            answer: '植株矮小、叶片由下而上逐渐变黄是缺氮的典型症状。建议增施氮肥，每 667m² 追施尿素 15-20kg。',
            answerCount: 12,
          ),
          const SizedBox(height: 8),
          _buildFaqItem(
            context: context,
            question: '大棚内 CO₂ 浓度多少合适？',
            answer: '一般蔬菜大棚 CO₂ 浓度维持在 800-1200ppm 为宜。过高会影响光合作用，过低导致植株生长缓慢。',
            answerCount: 8,
          ),
          const SizedBox(height: 8),
          _buildFaqItem(
            context: context,
            question: '番茄常见病害有哪些？如何预防？',
            answer: '晚疫病、灰霉病和叶霉病是棚栽番茄主要病害。控制棚内湿度在 60%-70%、加强通风是有效预防手段。',
            answerCount: 23,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildServiceCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String tag,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 26, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(tag,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: iconColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem({
    required BuildContext context,
    required String question,
    required String answer,
    required int answerCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.help_outline,
                  size: 18, color: Colors.blueAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(question,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(answer,
              style: TextStyle(
                  fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.5)),
          const SizedBox(height: 8),
          Text('$answerCount 条回复',
              style:
                  const TextStyle(fontSize: 11, color: Colors.blueAccent)),
        ],
      ),
    );
  }
}
