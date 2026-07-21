import 'package:flutter_test/flutter_test.dart';
import 'package:eagles_property/data/property_repository.dart';
import 'package:eagles_property/models/property_models.dart';

void main() {
  late MockPropertyRepository repository;

  setUp(() => repository = MockPropertyRepository());

  test('seeds tenant projects, units, and leads', () {
    expect(repository.tenants.length, 2);
    expect(repository.projectsForTenant('eagles').first.name, 'Eagle Heights');
    expect(repository.leadsForTenant('eagles').length, 5);
  });

  test('reserving a unit updates both unit and lead', () {
    repository.reserveUnit(tenantId: 'eagles', leadId: 'lead-2', unitId: 'e-101');

    expect(repository.findUnit('eagles', 'e-101')?.status, UnitStatus.reserved);
    expect(repository.findUnit('eagles', 'e-101')?.currentLeadId, 'lead-2');
    expect(repository.leadsForTenant('eagles').firstWhere((lead) => lead.id == 'lead-2').stage, LeadStage.reservation);
  });

  test('lead stage can move through the pipeline', () {
    repository.updateLeadStage('eagles', 'lead-5', LeadStage.qualified);
    expect(repository.leadsForTenant('eagles').firstWhere((lead) => lead.id == 'lead-5').stage, LeadStage.qualified);
  });
}
