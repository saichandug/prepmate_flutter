class Question {
  final String id;
  final String company;
  final String topic;
  final String difficulty;
  final String question;
  final String answer;
  final List<String> concepts;

  const Question({
    required this.id,
    required this.company,
    required this.topic,
    required this.difficulty,
    required this.question,
    this.answer = '',
    required this.concepts,
  });
}
