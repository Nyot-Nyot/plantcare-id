import 'package:flutter_test/flutter_test.dart';
import 'package:plantcare_id/models/treatment_guide.dart';

void main() {
  group('GuideStep equality', () {
    test(
      'should be equal when all fields including materials are the same',
      () {
        final step1 = GuideStep(
          stepNumber: 1,
          title: 'Test Step',
          description: 'Description',
          materials: ['Material 1', 'Material 2'],
          isCritical: true,
          estimatedTime: '10 minutes',
        );

        final step2 = GuideStep(
          stepNumber: 1,
          title: 'Test Step',
          description: 'Description',
          materials: ['Material 1', 'Material 2'],
          isCritical: true,
          estimatedTime: '10 minutes',
        );

        expect(step1, equals(step2));
        expect(step1.hashCode, equals(step2.hashCode));
      },
    );

    test('should NOT be equal when materials differ', () {
      final step1 = GuideStep(
        stepNumber: 1,
        title: 'Test Step',
        description: 'Description',
        materials: ['Material 1', 'Material 2'],
        isCritical: true,
      );

      final step2 = GuideStep(
        stepNumber: 1,
        title: 'Test Step',
        description: 'Description',
        materials: ['Material 1', 'Material 3'], // Different material
        isCritical: true,
      );

      expect(step1, isNot(equals(step2)));
    });

    test('should NOT be equal when materials order differs', () {
      final step1 = GuideStep(
        stepNumber: 1,
        title: 'Test Step',
        description: 'Description',
        materials: ['Material 1', 'Material 2'],
        isCritical: true,
      );

      final step2 = GuideStep(
        stepNumber: 1,
        title: 'Test Step',
        description: 'Description',
        materials: ['Material 2', 'Material 1'], // Different order
        isCritical: true,
      );

      expect(step1, isNot(equals(step2)));
    });

    test('should work correctly in Set collections', () {
      final step1 = GuideStep(
        stepNumber: 1,
        title: 'Test Step',
        description: 'Description',
        materials: ['Material 1'],
        isCritical: true,
      );

      final step2 = GuideStep(
        stepNumber: 1,
        title: 'Test Step',
        description: 'Description',
        materials: ['Material 2'], // Different material
        isCritical: true,
      );

      final step3 = GuideStep(
        stepNumber: 1,
        title: 'Test Step',
        description: 'Description',
        materials: ['Material 1'], // Same as step1
        isCritical: true,
      );

      final steps = {step1, step2, step3};

      // Should have 2 unique items (step1 and step2), step3 is duplicate of step1
      expect(steps.length, equals(2));
      expect(steps.contains(step1), isTrue);
      expect(steps.contains(step2), isTrue);
      expect(steps.contains(step3), isTrue); // step3 equals step1
    });
  });

  group('TreatmentGuide equality', () {
    test(
      'should be equal when all fields including steps and materials are the same',
      () {
        final step = GuideStep(
          stepNumber: 1,
          title: 'Step 1',
          description: 'Description',
          materials: ['Material A'],
          isCritical: true,
        );

        final guide1 = TreatmentGuide(
          id: '123',
          plantId: 'plant-1',
          diseaseName: 'Test Disease',
          severity: 'medium',
          guideType: 'treatment',
          steps: [step],
          materials: ['Tool 1', 'Tool 2'],
        );

        final guide2 = TreatmentGuide(
          id: '123',
          plantId: 'plant-1',
          diseaseName: 'Test Disease',
          severity: 'medium',
          guideType: 'treatment',
          steps: [step],
          materials: ['Tool 1', 'Tool 2'],
        );

        expect(guide1, equals(guide2));
        expect(guide1.hashCode, equals(guide2.hashCode));
      },
    );

    test('should NOT be equal when steps differ', () {
      final step1 = GuideStep(
        stepNumber: 1,
        title: 'Step 1',
        description: 'Description',
        materials: ['Material A'],
        isCritical: true,
      );

      final step2 = GuideStep(
        stepNumber: 1,
        title: 'Step 2', // Different title
        description: 'Description',
        materials: ['Material A'],
        isCritical: true,
      );

      final guide1 = TreatmentGuide(
        id: '123',
        plantId: 'plant-1',
        diseaseName: 'Test Disease',
        severity: 'medium',
        guideType: 'treatment',
        steps: [step1],
        materials: ['Tool 1'],
      );

      final guide2 = TreatmentGuide(
        id: '123',
        plantId: 'plant-1',
        diseaseName: 'Test Disease',
        severity: 'medium',
        guideType: 'treatment',
        steps: [step2],
        materials: ['Tool 1'],
      );

      expect(guide1, isNot(equals(guide2)));
    });

    test('should NOT be equal when materials differ', () {
      final step = GuideStep(
        stepNumber: 1,
        title: 'Step 1',
        description: 'Description',
        materials: ['Material A'],
        isCritical: true,
      );

      final guide1 = TreatmentGuide(
        id: '123',
        plantId: 'plant-1',
        diseaseName: 'Test Disease',
        severity: 'medium',
        guideType: 'treatment',
        steps: [step],
        materials: ['Tool 1', 'Tool 2'],
      );

      final guide2 = TreatmentGuide(
        id: '123',
        plantId: 'plant-1',
        diseaseName: 'Test Disease',
        severity: 'medium',
        guideType: 'treatment',
        steps: [step],
        materials: ['Tool 1', 'Tool 3'], // Different materials
      );

      expect(guide1, isNot(equals(guide2)));
    });
  });
}
