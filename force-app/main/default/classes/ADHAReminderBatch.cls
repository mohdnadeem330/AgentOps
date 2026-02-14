/*
*****************************************************************************
Apex Class Name : ADHAReminderBatch
Created Date    : Sept 04, 2023
@description    :  
@author         : Moh Sarfaraj

Modification Log:
Ver   Date              Author                               Modification
1.0   04-09-2023      Moh Sarfaraj                          Initial Version
******************************************************************************
*/
public class ADHAReminderBatch implements Database.Batchable<sObject>,Schedulable{
   private String query = '';
   private String adhaQueue = System.Label.ADHAQueue;
   private static List<String> listReminders = new List<String>(System.Label.ADHAReminder.split(',')); //Reminder 1,Reminder 2
   private static List<String> listReminderTimes = new List<String>(System.Label.ADHAReminderTime.split(','));// 48,96,120

   public ADHAReminderBatch(){}

   public Database.QueryLocator start(Database.BatchableContext BC){
      query += 'SELECT Id,CreatedDate,SendReminder__c,AssignToRoundRobin__c,Bag_Lead_Assigned_Manually_TO_RM__c FROM Lead WHERE AssignToRoundRobin__c = false AND Bag_Lead_Assigned_Manually_TO_RM__c = false AND Owner_Name__c = \''+String.escapeSingleQuotes(adhaQueue)+'\'';
      return Database.getQueryLocator(query);
   }

   public void execute(Database.BatchableContext BC, List<sObject> scope){
      List<Lead> listLeads = new List<Lead>();
      listLeads.addAll((List<Lead>)scope);
      List<Lead> listLeadsToUpdate = new List<Lead>();
      
      for(Lead eachLead : listLeads){
         DateTime createdDate = eachLead.CreatedDate;
         createdDate = Test.isRunningTest() ? createdDate.addHours(-(Integer.valueOf(listReminderTimes[0]) + 1)) : eachLead.CreatedDate;
         
         String setValue = setReminderValue(eachLead.SendReminder__c, createdDate);

         if(listReminders.contains(setValue)){
            eachLead.SendReminder__c = setValue;
            listLeadsToUpdate.add(eachLead);
         }else if(String.isNotBlank(setValue)){
            eachLead.AssignToRoundRobin__c = true;
            eachLead.Bag_Lead_Assigned_Manually_TO_RM__c = true;
            listLeadsToUpdate.add(eachLead);
         }
      }
      System.debug(listLeadsToUpdate);
      if(!listLeadsToUpdate.isEmpty()){
         update listLeadsToUpdate;
         System.debug(listLeadsToUpdate);
      }
   }

   public void finish(Database.BatchableContext BC){
   }

   private static String setReminderValue(String reminder, DateTime createdDate){
      if(String.isBlank(reminder) && createdDate.addHours(Integer.valueOf(listReminderTimes[0])) <= System.now() && createdDate.addHours(Integer.valueOf(listReminderTimes[1])) >= System.now()){
         return listReminders[0];
      }else if(reminder == listReminders[0] && createdDate.addHours(Integer.valueOf(listReminderTimes[1])) <= System.now() && createdDate.addHours(Integer.valueOf(listReminderTimes[2])) >= System.now()){
         return listReminders[1];
      }else if(reminder == listReminders[1] && createdDate.addHours(Integer.valueOf(listReminderTimes[2])) <= System.now()){
         return 'setToRR';
      }
      return '';
   }
   
   public void execute(SchedulableContext sc){
      Database.executebatch(new ADHAReminderBatch(), 1);
   }
}