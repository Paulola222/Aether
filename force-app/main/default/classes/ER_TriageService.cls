public with sharing class ER_TriageService {
    
    @AuraEnabled(cacheable=true)
    public static List<CaseWrapper> getWaitingPatients() {
        List<Case> cases = [SELECT Id, Contact.Name, Priority, CreatedDate
                            FROM Case
                            WHERE Status = 'Waiting'];

        // Manual sorting in Apex
        cases.sort(new PrioritySorter());

        List<CaseWrapper> wrappedCases = new List<CaseWrapper>();
        for (Case c : cases) {
            wrappedCases.add(new CaseWrapper(c));
        }
        return wrappedCases;
    }
    
    public class PrioritySorter implements Comparator<Case> {
        public Integer compare(Case a, Case b) {
            Integer priorityA = getPriorityValue(a.Priority);
            Integer priorityB = getPriorityValue(b.Priority);
            if (priorityA != priorityB) {
                return priorityA - priorityB;
            } else {
                if (a.CreatedDate < b.CreatedDate) {
                    return -1;
                } else if (a.CreatedDate > b.CreatedDate) {
                    return 1;
                } else {
                    return 0;
                }
            }
        }
    
        private Integer getPriorityValue(String priority) {
            if (priority == 'High') return 1;
            if (priority == 'Medium') return 2;
            if (priority == 'Low') return 3;
            return 4; // unknown priorities
        }
    }
    

    public class CaseWrapper {
        @AuraEnabled public Id Id;
        @AuraEnabled public String ContactName;
        @AuraEnabled public String Priority;
        @AuraEnabled public Datetime CreatedDate;
        
        public CaseWrapper(Case c) {
            Id = c.Id;
            ContactName = c.Contact != null ? c.Contact.Name : 'Unknown';
            Priority = c.Priority;
            CreatedDate = c.CreatedDate;
        }
    }
}
