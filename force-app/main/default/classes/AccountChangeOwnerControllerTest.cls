@isTest
private class AccountChangeOwnerControllerTest {
    
    @isTest static  void callMethods() {
        
        List<Account> accountList = AccountChangeOwnerController.getAllAccountsRecords(New List<String>{'Name = \'%Ali%\''});

        List<Object> objList = AccountChangeOwnerController.getRecordsByName('Account', 'Ali', 'Name = \'%Ali%\'');

        Account acc = TestObjectsFactory.getAgencyAccountRecord('Test Account','G996324');
        insert acc;

        Map<String, Object> accountMap = new Map<String, Object>();
        accountMap.put('id', acc.Id);

        List<Map<String, Object>> selectedAccounts = new List<Map<String, Object>>();
        selectedAccounts.add(accountMap);

        AccountChangeOwnerController.updateSelectedAccounts(selectedAccounts, UserInfo.getUserId());
    }
}