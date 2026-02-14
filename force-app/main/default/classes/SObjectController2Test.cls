@isTest
public with sharing class SObjectController2Test {

    static testMethod void test() {
		Account a1 = new Account(
			AccountNumber='1',
            Website='https://trailblazer.me/id/ericsmith',
            Type='Type1',
            FirstName = 'FirstName',
            MiddleName = 'MiddleName ',
            LastName = 'LastName' ,
            BillingCountry='United Arab Emirates',
            Phone ='97146019306',
            AccountSource = 'Midis',
            PersonEmail = 'test1@yahoo.com',
            Email__c = 'test12@yahoo.com',
			Description='D1');
        insert a1;
		Account a2 = new Account(
			AccountNumber='2',
            Website='https://ericsplayground.wordpress.com/blog/',
            Type='Type2',
            FirstName = 'FirstName2',
            MiddleName = 'MiddleName2 ',
            LastName = 'LastName2' ,
            BillingCountry='United Arab Emirates',
            Phone ='97146019305',
            PersonEmail = 'test2@yahoo.com',
            Email__c = 'test13@yahoo.com',
			Description='D2');
        insert a2;

        Account[] accts = [Select Id, Name, OwnerId from Account];
        String fieldnames = 'Name,Id,OwnerId,AccountNumber,Website,Type,Description,IsDeleted,CreatedDate,AnnualRevenue,Fax,LastActivityDate';
        String testResponse = SObjectController2.getReturnResults(accts, fieldnames);
        System.assert(testResponse.contains('"noEditFieldList":['));
        System.assert(testResponse.contains('"lookupFieldList":["OwnerId"]'));
        
        Account[] empty = [Select Id, Name, OwnerId from Account Where Name='NotInAccounts'];
        String testEmpty = SObjectController2.getReturnResults(empty, fieldnames);
        System.assert(testEmpty.contains('"objectName":"EmptyCollection"'));
        
        SObjectController2.getCPEReturnResults('Account');
    }

}