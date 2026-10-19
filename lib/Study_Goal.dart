import 'package:flutter/material.dart';

// =============================================================================
// 1. DRY (지식의 단일 기준): 제목 길이 제약 한곳에서 관리
// =============================================================================
class GoalRules {
  static const int maxTitleLength = 20;
}

// =============================================================================
// 2. 도메인 모델 (캡슐화 & '묻지 말고 시켜라'): 내부 상태 보호 및 행동 요청
// =============================================================================
class StudyGoal {
  StudyGoal(this.title);

  final String title;

  // 외부에서 직접 변경 불가 (_private)
  bool _isDone = false;
  bool get isDone => _isDone;

  // 상태 변경 규칙을 객체 내부에 숨김 (Tell, Don't Ask)
  void toggle() {
    _isDone = !_isDone;
  }
}

// =============================================================================
// 3. SOLID - SRP (단일 책임 원칙): 입력값 검증 로직 분리
// =============================================================================
class GoalValidator {
  static String? validateTitle(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return '목표를 입력하세요'; // AC2: 빈 값 오류 메시지
    }
    if (trimmed.length > GoalRules.maxTitleLength) {
      return '목표는 ${GoalRules.maxTitleLength}자 이하로 입력하세요';
    }
    return null;
  }
}

// =============================================================================
// 4. SOLID - OCP / DIP: 저장소 추상 인터페이스
// =============================================================================
abstract interface class GoalRepository {
  void save(StudyGoal goal);
  List<StudyGoal> load();
}

// 5. YAGNI & KISS: 지금은 단순 메모리 저장소로 수용조건 만족
final class MemoryGoalRepository implements GoalRepository {
  final List<StudyGoal> _goals = [];

  @override
  void save(StudyGoal goal) {
    _goals.add(goal);
  }

  @override
  List<StudyGoal> load() {
    return List.unmodifiable(_goals);
  }
}

// =============================================================================
// 6. Flutter UI 앱 구현
// =============================================================================
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'week03_goal_lab',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: StudyGoalPage(repository: MemoryGoalRepository()),
    );
  }
}

class StudyGoalPage extends StatefulWidget {
  const StudyGoalPage({super.key, required this.repository});

  final GoalRepository repository;

  @override
  State<StudyGoalPage> createState() => _StudyGoalPageState();
}

class _StudyGoalPageState extends State<StudyGoalPage> {
  final TextEditingController _controller = TextEditingController();
  String? _errorMessage;

  // ---------------------------------------------------------------------------
  // AC1 & AC2: 목표 추가 기능
  // ---------------------------------------------------------------------------
  void _addGoal() {
    final text = _controller.text;
    final error = GoalValidator.validateTitle(text);

    // AC2: 검증 실패 시 입력창 하단에 에러 문구 표시
    if (error != null) {
      setState(() {
        _errorMessage = error;
      });
      return;
    }

    // AC1: 정상 입력 시 목록에 추가 및 입력창 초기화
    setState(() {
      _errorMessage = null;
      widget.repository.save(StudyGoal(text.trim()));
      _controller.clear();
    });
  }

  // ---------------------------------------------------------------------------
  // AC3: 완료 상태 전환 기능 (TODO 구현 부분)
  // ---------------------------------------------------------------------------
  void _toggleGoal(StudyGoal goal) {
    setState(() {
      goal.toggle(); // 객체에게 완료 상태 전환을 요청 (Tell)
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goals = widget.repository.load();

    return Scaffold(
      appBar: AppBar(
        title: const Text('StudyGoal 추가 및 완료 전환'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 1. 입력창 및 추가 버튼 영역
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      labelText: '새 학습 목표',
                      hintText: '예: Dart 캡슐화 복습하기',
                      errorText: _errorMessage, // AC2 에러 표시
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _addGoal,
                    child: const Text('추가'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // 2. 학습 목표 목록 영역
            Expanded(
              child: goals.isEmpty
                  ? const Center(child: Text('등록된 학습 목표가 없습니다.'))
                  : ListView.builder(
                      itemCount: goals.length,
                      itemBuilder: (context, index) {
                        final goal = goals[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: Checkbox(
                              value: goal.isDone,
                              onChanged: (_) => _toggleGoal(goal), // AC3 연결
                            ),
                            title: Text(
                              goal.title,
                              style: TextStyle(
                                decoration: goal.isDone
                                    ? TextDecoration.lineThrough // 완료 시 취소선
                                    : TextDecoration.none,
                              ),
                            ),
                            trailing: Text(
                              goal.isDone ? '완료' : '미완료',
                              style: TextStyle(
                                color: goal.isDone ? Colors.green : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}