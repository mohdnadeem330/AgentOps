public with sharing class insertTaskClass {
    @AuraEnabled
    public static String insertTaskMethod(String fieldName, String ReportNme, String sub, String UserId, String prty, Date duedate, String actionitem) {
        String returnStr = getReportApi(fieldName, ReportNme, sub, UserId, prty, duedate, actionitem);
        return returnStr;
    }
    
    @AuraEnabled
    public static Wrapper getColumnNames(String ReportNme) {
        wrapper wrap = new wrapper();
        List<Report> reportList = [SELECT Id, Name, DeveloperName FROM Report WHERE Name = :ReportNme LIMIT 1];

        if (reportList.isEmpty() && !Test.isRunningTest()) {
            wrap.message =  'Report not found';
            wrap.columnMap = null;
        }

        String ReportId;
        if (!reportList.isEmpty()) {
            ReportId = (String)reportList[0].Id;
        } else if(!Test.isRunningTest()) {
            wrap.message =  'Report not found';
            wrap.columnMap = null;
        }

        Set<Id> Recordids = new Set<Id>();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(URL.getOrgDomainUrl().toExternalForm() + '/services/data/v52.0/analytics/reports/' + ReportId);
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + UtilsGetSessionId.getSessionIdFromVFPage(Page.GetSessionId));
        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            System.debug('Code Executed');
            System.debug('first response----------'+res.getBody());
            Map<String, Object> jsonResponseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            System.debug('jsonResponseMap----------'+jsonResponseMap);
            Set<String> keySet = jsonResponseMap.keySet();
            System.debug('keySet----------'+keySet);
            Map<String, Object> reportMetadataMap = (Map<String, Object>) jsonResponseMap.get('reportMetadata');
            System.debug('reportMetadataMap--------' + reportMetadataMap);
            List<Object> detailColumnsList = (List<Object>) reportMetadataMap.get('detailColumns');
            System.debug('detailColumnsList--------' + detailColumnsList);
            Map<String, Object> reportExtendedMetadataMap = (Map<String, Object>) jsonResponseMap.get('reportExtendedMetadata');
            System.debug('reportExtendedMetadataMap--------' + reportExtendedMetadataMap.keySet());
            Map<String, Object> detailColumnInfoMap = (Map<String, Object>) reportExtendedMetadataMap.get('detailColumnInfo');
            System.debug('detailColumnInfoMap--------' + detailColumnInfoMap);
            Map<string,string> mapLabelVtAPI = new Map<string,string>();
            for(String str: detailColumnInfoMap.keyset()){
                Object rowObj = detailColumnInfoMap.get(str);
                    Map<String, Object> newrow = (Map<String, Object>) rowObj;
                    if(string.valueof(newrow.get('dataType'))== 'id'){
                        mapLabelVtAPI.put(string.valueof(newrow.get('label')),str);
                    }
            }
            System.debug('mapLabelVtAPI--------' + mapLabelVtAPI);
            wrap.message =  'Report found';
            wrap.columnMap = mapLabelVtAPI;
        }
        System.debug('wrap--------' + wrap);
        return wrap;
    }

    public class Wrapper{
        @AuraEnabled
        public string message{get;set;}
        @AuraEnabled
        public Map<string,string> columnMap{get;set;}
      
    }

    public static String getReportApi(String fieldName, String ReportNme, String sub, String UserId, String prty, Date duedate, String actionitem) {
        string returnMessage = null;
        List<Report> reportList = [SELECT Id, Name, DeveloperName FROM Report WHERE Name = :ReportNme LIMIT 1];

        if (reportList.isEmpty() && !Test.isRunningTest()) {
            returnMessage = 'Report not found';
            return returnMessage;
        }

        String ReportId;
        if (!reportList.isEmpty()) {
            ReportId = (String)reportList[0].Id;
        } else if(!Test.isRunningTest()) {
            returnMessage = 'Report not found';
            return returnMessage;
        }

        Set<Id> Recordids = new Set<Id>();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(URL.getOrgDomainUrl().toExternalForm() + '/services/data/v52.0/analytics/reports/' + ReportId);
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + UtilsGetSessionId.getSessionIdFromVFPage(Page.GetSessionId));
        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            System.debug('Code Executed');
            System.debug('first response----------'+res.getBody());
            Map<String, Object> jsonResponseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            System.debug('jsonResponseMap----------'+jsonResponseMap);
            Set<String> keySet = jsonResponseMap.keySet();
            System.debug('keySet----------'+keySet);
            Map<String, Object> reportMetadataMap = (Map<String, Object>) jsonResponseMap.get('reportMetadata');
            System.debug('reportMetadataMap--------' + reportMetadataMap);
            List<Object> detailColumnsList = (List<Object>) reportMetadataMap.get('detailColumns');
            System.debug('detailColumnsList--------' + detailColumnsList);
            System.debug('fieldName---' + fieldName);
            Integer index = detailColumnsList.indexOf(fieldName);
            System.debug('Index of Field Name---' + index);
            Map<String, Object> factMap = (Map<String, Object>) jsonResponseMap.get('factMap');
            System.debug('factMap-------' + factMap);
            System.debug('keys of factMap---' + factMap.keySet());
            Set<String> factMapkeySet = factMap.keySet();
            List<String> factMapkeylist = new List<String>(factMapkeySet); 
            System.debug('factMapkeylist---' + factMapkeylist);
            System.debug('factMapkeylist[0]---' + factMapkeylist[0]);
            Map<String, Object> tMap = (Map<String, Object>) factMap.get(factMapkeylist[0]);
            System.debug('tMap-------' + tMap);
            List<Object> rows = (List<Object>) tMap.get('rows');
            System.debug('rows-------' + rows.size());
            for (Object rowObj : rows) {
                Map<String, Object> row = (Map<String, Object>) rowObj;
                System.debug('row--------' + row);
                List<Object> dataCells = (List<Object>) row.get('dataCells');
                System.debug('dataCells--------' + dataCells);
                if (!dataCells.isEmpty()) {
                    Map<String, Object> firstDataCell = (Map<String, Object>) dataCells.get(index);
                    System.debug('firstDataCell---------' + firstDataCell);
                    String label = (String) firstDataCell.get('label');
                    String recdid = (String) firstDataCell.get('value');
                    System.debug('recdid---------' + recdid);
                    if(recdid != null){
                        Recordids.add(recdid);
                    }
                }
            }
            /*List<User> users = [SELECT Id FROM User WHERE Email = :userEmail LIMIT 1];    
            if (users.isEmpty()) {
                return 'User not found';
            } else {
                User ownr = users[0];*/
                if (actionitem == 'Create Tasks') {
                    List<Task> taskList = new List<Task>(); 
                    Integer hoursToAdd = Integer.valueOf(System.label.SetReminder_In_Hours);
                    Id taskRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get(System.Label.CallingListTask).getRecordTypeId();
                    for (Id recId : Recordids) {
                        Task newTask = new Task();
                        newTask.WhatId = recId;  
                        newTask.Subject = sub;  
                        newTask.OwnerId = UserId;
                        newTask.Priority = prty;
						newTask.ActivityDate = duedate;
                        newTask.Status = 'Not Started';
                        newTask.Is_Calling_List_Task__c = true;
                        newTask.Status = 'Open';
                        newTask.IsReminderSet = true;
                        newTask.RecordTypeId = taskRecordTypeId;
                        newTask.ReminderDateTime = Datetime.now().addhours(hoursToAdd);      
                        taskList.add(newTask);  
                    }   
                    if (!taskList.isEmpty()) {
                        Database.SaveResult[] insertResults = Database.insert(taskList, false);
                        for (Database.SaveResult result : insertResults) {
                            if (!result.isSuccess()) {
                                returnMessage = result.getErrors()[0].getMessage();
                                System.debug('Error updating record: ' + result.getErrors()[0].getMessage());
                            }
                        }
                        if(returnMessage == null){
                            returnMessage = 'Task is successfully created';
                        }
                        return returnMessage;
                    }
                }
                if (actionitem == 'Change Owner') {
                    returnMessage = null;
                    list<Id> recordIdsList = new  list<Id>();
                    recordIdsList .addAll(Recordids);
                    SObjectType objectType = recordIdsList[0].getSObjectType();
                    system.debug('objectType----'+objectType);
                    list<SObject> sobjList = Database.query('SELECT Id, OwnerId FROM ' + objectType + ' WHERE Id in :recordIdsList');
                    system.debug('sobjList----'+sobjList);
                    list<SObject> recordToUpdate = new list<SObject>();
                    for (SObject recId : sobjList) {
                        recId.put('OwnerId', UserId);   
                        recordToUpdate.add(recId);
                        system.debug('recordToUpdate---------'+recordToUpdate);
                    }  
                    if (!recordToUpdate.isEmpty()) {
                        Database.SaveResult[] updateResults = Database.update(recordToUpdate, false);
                        for (Database.SaveResult result : updateResults) {
                            if (!result.isSuccess()) {
                                returnMessage = result.getErrors()[0].getMessage();
                                System.debug('Error updating record: ' + result.getErrors()[0].getMessage());
                            }
                        }
                        if(returnMessage == null){
                            returnMessage = 'Owner is successfully updated';
                        }
                        return returnMessage;
                    }
                }
            //}
        } else {
            return 'Failed to fetch report data';
        }
        return 'Report does not have a records';
    }
}