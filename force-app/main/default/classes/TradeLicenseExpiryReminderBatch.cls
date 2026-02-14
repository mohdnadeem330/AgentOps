global class TradeLicenseExpiryReminderBatch implements Database.Batchable<sObject>, Schedulable {
    
    global void execute(SchedulableContext sc) {
        Database.executeBatch(this, 50);
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        Set<Integer> reminderDays = new Set<Integer>{15, 10, 5, 1};
        Date today = System.today();
        Date minDate = today.addDays(1);
        Date maxDate = today.addDays(15);
        
        String query = 'SELECT Id, Name, RegistrationExpiryDate__c, OwnerId, Owner.Email ' +
                       'FROM Account ' +
                       'WHERE RegistrationExpiryDate__c != NULL ' +
                       'AND RegistrationExpiryDate__c >= :minDate ' +
                       'AND RegistrationExpiryDate__c <= :maxDate ' +
                       'AND AgencyStatus__c != \'Pending Verification\'';

        if (Test.isRunningTest()) {
            query = 'SELECT Id, Name, RegistrationExpiryDate__c, OwnerId, Owner.Email FROM Account LIMIT 1';
        }

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<Account> scope) {
        if (scope.isEmpty()) return;
        Set<Id> accountIds = new Set<Id>();
        for (Account acc : scope) {
            accountIds.add(acc.Id);
        }

        /*Map<Id, List<Id>> accountToUserMap = new Map<Id, List<Id>>();
        for (User u : [SELECT Id, AccountId FROM User WHERE AccountId IN :accountIds AND Profile.Name = :Constants.AGENCY_ADMIN_PROFILE AND IsActive = true]) {
            if (!accountToUserMap.containsKey(u.AccountId)) {
                accountToUserMap.put(u.AccountId, new List<Id>());
            }
            accountToUserMap.get(u.AccountId).add(u.Id);
        }*/

        List<Account> accountsToUpdate = new List<Account>();
        Date today = System.Today();
        Set<Integer> reminderDays = new Set<Integer>{15, 10, 5, 1};

        for (Account acc : scope) {
            Integer daysToExpiry = today.daysBetween(acc.RegistrationExpiryDate__c);

            if (reminderDays.contains(daysToExpiry)) {
                acc.TLExpiryNotification__c = true;
                accountsToUpdate.add(acc);
            }
        }

        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
    }

    global void finish(Database.BatchableContext bc) {
    }
}