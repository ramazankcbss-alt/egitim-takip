import 'package:egitim_takip/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Konu sayfa aralığı', () {
    const t = Topic(name: 'Kesirler', start: 10, end: 14);
    expect(t.hasRange, isTrue);
    expect(t.pageCount, 5);
    expect(t.pages, [10, 11, 12, 13, 14]);
  });

  test('Net hesabı', () {
    TestResult r(int penalty) => TestResult(
          id: '1',
          name: 'Deneme',
          subject: 'Matematik',
          correct: 15,
          wrong: 3,
          blank: 2,
          penalty: penalty,
          date: null,
          createdBy: '',
        );
    expect(r(0).net, 15);
    expect(r(3).net, 14);
    expect(r(4).net, 14.25);
  });
}
