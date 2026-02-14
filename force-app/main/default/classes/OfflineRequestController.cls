public class OfflineRequestController {
    @auraEnabled
    public static void cancelOffRequest(OfflineRequest__c objOfflineRequest){
        system.debug('objOfflineRequest>>>>>>>'+objOfflineRequest);
        List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest> ();
		Map<ID,ProcessInstance> piMap = New Map<ID,ProcessInstance>([Select Id from ProcessInstance where TargetObjectId= :objOfflineRequest.Id]);
		for(ProcessInstanceWorkItem pp : [Select Id from ProcessInstanceWorkItem where ProcessInstanceId IN :piMap.keySet()]){
			// if there's a work item, set the action to 'removed' and execute
            Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
            req2.setAction('Removed');
            req2.setWorkitemId(pp.Id);
            requests.add(req2);
        }
        Approval.ProcessResult[] processResults = Approval.process(requests, true);
        objOfflineRequest.Status__c = 'Cancelled';
        update objOfflineRequest;
    }
    
    @auraEnabled
    public static void deleteOffRequest(OfflineRequest__c objOfflineRequest){
        delete objOfflineRequest;
    }
    
	@auraEnabled
    public static List<object> getOfflineRequest(){
        List<object> lstResults = new List<object>();
        for(OfflineRequest__c objOfflineRequest : [SELECT 
                                                   Name,
                                                   Reason__c,
                                                   StartTime__c,
                                                   Status__c,
                                                   EndTime__c 
                                                   FROM OfflineRequest__c
                                                   WHERE User__c =: userInfo.getUserId() 
                                                   ORDER BY lastmodifiedDate DESC LIMIT 7]){
			boolean editable = false;
			boolean deletable = false;
			boolean cancel = false;
			
			if(objOfflineRequest.Status__c == 'Awaiting approval'){
				//editable = true;
                cancel = true;
            }else if(objOfflineRequest.Status__c == 'Rejected' || objOfflineRequest.Status__c == 'Cancelled'){
               	editable = true;
                deletable = true;
            }
			lstResults.add(new Map<String,object>{
                   'editable'=> editable,
                	'deletable'=> deletable,
                	'cancel' => cancel,
                       'Id'=>objOfflineRequest.Id,
                       'RequestNumber'=> objOfflineRequest.Name,
                       'reason'=>objOfflineRequest.Reason__c,
                       'startTime'=>objOfflineRequest.StartTime__c,
                       'endTime'=>objOfflineRequest.EndTime__c,
                       'Status'=>objOfflineRequest.Status__c
			});
                                                       
        }
       // return [SELECT Name,Reason__c,StartTime__c,Status__c,EndTime__c FROM OfflineRequest__c WHERE User__c =: userInfo.getUserId() LIMIT 10];
       return lstResults;
    }
    
    @auraEnabled
    public static map<String, object> validateOfflineRequest(OfflineRequest__c objOfflineRequest){
        map<String, object> resutls = new map<String, object>();
        String startDayOfWeek = (objOfflineRequest.StartTime__c). format('EEEE');
        String endDayOfWeek = (objOfflineRequest.EndTime__c). format('EEEE');
        time startTime = (objOfflineRequest.StartTime__c).time();
        time endTime = (objOfflineRequest.EndTime__c).time();
        boolean startTimeValidate = validateBusinesshours(startDayOfWeek, startTime);
        boolean endTimeValidate = validateBusinesshours(endDayOfWeek, endTime);
        boolean isValidatStartTime = validateStartTime(objOfflineRequest.StartTime__c);
        boolean isValidatEndTime = validateEndTime(objOfflineRequest.EndTime__c, objOfflineRequest.StartTime__c);
        resutls.put('startTimeValidate',startTimeValidate);
        resutls.put('endTimeValidate',endTimeValidate);
        resutls.put('existingOfflineRequest', checkExisintgOfflineRequest(objOfflineRequest));
        resutls.put('startTime',isValidatStartTime);
        resutls.put('endTime',isValidatEndTime);
        return resutls;
    }
    
    public static boolean validateStartTime(dateTime StartTime){
       boolean isValidatStartTime = true;
        if(StartTime < system.now()){
            isValidatStartTime = false;
        }
        return isValidatStartTime;
    }
     public static boolean validateEndTime(dateTime EndTime, dateTime StartTime){
       boolean isValidatEndTime = true;
        if(EndTime < system.now() || EndTime < StartTime){
            isValidatEndTime = false;
        }
        return isValidatEndTime;
    }
    
    Public Static List<OfflineRequest__c> checkExisintgOfflineRequest(OfflineRequest__c objOfflineRequest){
        return  [SELECT Id FROM OfflineRequest__c WHERE StartTime__c =: objOfflineRequest.StartTime__c AND EndTime__c =: objOfflineRequest.EndTime__c 
                AND (Status__c = :Constants.OFFLINE_REQUEST_STATUS_AWAITING_APPROVAL OR Status__c =:Constants.OFFLINE_REQUEST_STATUS_APPROVE ) ];
    }
	
    public static boolean validateBusinesshours(String dayOfWeek, time currentTime){
        List<BusinessHours> lstBusinessHours = [SELECT IsActive,Name,FridayEndTime,FridayStartTime,MondayEndTime,MondayStartTime,
                                                SaturdayEndTime,SaturdayStartTime,SundayEndTime,SundayStartTime,ThursdayEndTime,
                                                ThursdayStartTime,TimeZoneSidKey,TuesdayEndTime,TuesdayStartTime,
                                                WednesdayEndTime,WednesdayStartTime
                                                FROM BusinessHours Where IsActive = true AND Name=: Constants.ALDAR_BUSINESS_HOURS LIMIT 1];
        boolean workingHours = false;
        time startTime = (system.now()).time();
        time endTime = (system.now()).time();
            if(!lstBusinessHours.isEmpty()){
                if(dayOfWeek == Constants.SUNDAY){
                    startTime = lstBusinessHours[0].SundayStartTime;
                    endTime = lstBusinessHours[0].SundayEndTime;
                    if(startTime <= currentTime && endTime >= currentTime){
                        workingHours = true;
                    }
                }else if(dayOfWeek == Constants.MONDAY){
                    startTime = lstBusinessHours[0].MondayStartTime;
                    endTime = lstBusinessHours[0].MondayEndTime;
                    if(startTime <= currentTime && endTime >= currentTime){
                        workingHours = true;
                    }
                }else if(dayOfWeek == Constants.TUESDAY){
                    startTime = lstBusinessHours[0].TuesdayStartTime;
                    endTime = lstBusinessHours[0].TuesdayEndTime;
                    if(startTime <= currentTime && endTime >= currentTime){
                        workingHours = true;
                    }
                }else if(dayOfWeek == Constants.WEDNESDAY){
                    startTime = lstBusinessHours[0].WednesdayStartTime;
                    endTime = lstBusinessHours[0].WednesdayEndTime;
                    if(startTime <= currentTime && endTime >= currentTime){
                        workingHours = true;
                    }
                }else if(dayOfWeek == Constants.THURSDAY){
                    startTime = lstBusinessHours[0].ThursdayStartTime;
                    endTime = lstBusinessHours[0].ThursdayEndTime;
                    if(startTime <= currentTime && endTime >= currentTime){
                        workingHours = true;
                    }
                }else if(dayOfWeek == Constants.FRIDAY){
                    startTime = lstBusinessHours[0].FridayStartTime;
                    endTime = lstBusinessHours[0].FridayEndTime;
                    if(startTime <= currentTime && endTime >= currentTime){
                        workingHours = true;
                    }
                }else if(dayOfWeek == Constants.SATURDAY){
                    startTime = lstBusinessHours[0].SaturdayStartTime;
                    endTime = lstBusinessHours[0].SaturdayEndTime;
                    if(startTime <= currentTime && endTime >= currentTime){
                        workingHours = true;
                    }
                }
            }else{
                workingHours = true;
            }
        return workingHours;
    }    
    @auraEnabled
    public static Map<String, Object> checkApprovedRequest(){
        Map<String, Object> results = new Map<String, Object>();
        List<BusinessHours> lstBusinessHours = [SELECT IsActive,Name,FridayEndTime,FridayStartTime,MondayEndTime,MondayStartTime,
                                                SaturdayEndTime,SaturdayStartTime,SundayEndTime,SundayStartTime,ThursdayEndTime,
                                                ThursdayStartTime,TimeZoneSidKey,TuesdayEndTime,TuesdayStartTime,
                                                WednesdayEndTime,WednesdayStartTime
                                                FROM BusinessHours Where IsActive = true AND Name='Aldar Business Hours' LIMIT 1];
        String dayOfWeek = (system.now()). format('EEEE');
        time startTime = (system.now()).time();
        time endTime = (system.now()).time();
        time currentTime = (system.now()).time();
        boolean workingHours = false;
        if(dayOfWeek == Constants.SUNDAY){
            startTime = lstBusinessHours[0].SundayStartTime;
            endTime = lstBusinessHours[0].SundayEndTime;
            if(startTime <= currentTime && endTime >= currentTime){
                workingHours = true;
            }
        }else if(dayOfWeek == Constants.MONDAY){
            startTime = lstBusinessHours[0].MondayStartTime;
            endTime = lstBusinessHours[0].MondayEndTime;
            if(startTime <= currentTime && endTime >= currentTime){
                workingHours = true;
            }
        }else if(dayOfWeek == Constants.TUESDAY){
            startTime = lstBusinessHours[0].TuesdayStartTime;
            endTime = lstBusinessHours[0].TuesdayEndTime;
            if(startTime <= currentTime && endTime >= currentTime){
                workingHours = true;
            }
        }else if(dayOfWeek == Constants.WEDNESDAY){
            startTime = lstBusinessHours[0].WednesdayStartTime;
            endTime = lstBusinessHours[0].WednesdayEndTime;
            if(startTime <= currentTime && endTime >= currentTime){
                workingHours = true;
            }
        }else if(dayOfWeek == Constants.THURSDAY){
            startTime = lstBusinessHours[0].ThursdayStartTime;
            endTime = lstBusinessHours[0].ThursdayEndTime;
            if(startTime <= currentTime && endTime >= currentTime){
                workingHours = true;
            }
        }else if(dayOfWeek == Constants.FRIDAY){
            startTime = lstBusinessHours[0].FridayStartTime;
            endTime = lstBusinessHours[0].FridayEndTime;
            if(startTime <= currentTime && endTime >= currentTime){
                workingHours = true;
            }
        }else if(dayOfWeek == Constants.SATURDAY){
            startTime = lstBusinessHours[0].SaturdayStartTime;
            endTime = lstBusinessHours[0].SaturdayEndTime;
            if(startTime <= currentTime && endTime >= currentTime){
                workingHours = true;
            }
        }
        results.put('workingHours',workingHours);
        List<OfflineRequest__c> lstOfflineReq = [SELECT Name,Reason__c,StartTime__c,Status__c,EndTime__c FROM OfflineRequest__c 
                									WHERE User__c =: userInfo.getUserId() AND Status__c=:Constants.OFFLINE_REQUEST_STATUS_APPROVE AND 
                									EndTime__c >= :system.now() AND StartTime__c <= :system.now()]; 
        results.put('approvedOfflineReq',lstOfflineReq);
        return results;
    }
    
    @auraEnabled
    public static void sendManagerApprovel(String offLineRequestId){
        OfflineRequest__c objOfflineRequest = [SELECT Name,Reason__c,StartTime__c,Status__c,EndTime__c,User__c,User__r.ManagerId FROM OfflineRequest__c WHERE Id =:offLineRequestId];
       
        Approval.ProcessSubmitRequest approvalRequest = new Approval.ProcessSubmitRequest();
        approvalRequest.setComments('Requesting for Offline for the mentioned Date & time');
        approvalRequest.setObjectId(offLineRequestId);
        if(!Test.isRunningTest()){
            Approval.ProcessResult approvalResult = Approval.process(approvalRequest);
        }
		
        
        CustomNotificationType notificationType = [SELECT DeveloperName FROM CustomNotificationType WHERE DeveloperName=: Constants.CUSTOM_NOTIFICATION_API_NAME];
        Messaging.CustomNotification currNotification = new Messaging.CustomNotification();
        currNotification.setTitle(Constants.CUSTOM_NOTIFICATION_TITTLE);
        currNotification.setBody(userInfo.getFirstName() +' ' +userInfo.getLastName() + Constants.CUSTOM_NOTIFICATION_MSG);
		currNotification.setNotificationTypeId(notificationType.Id);
        currNotification.setTargetId(objOfflineRequest.Id);
        
		currNotification.send(new set<string> { objOfflineRequest.User__r.ManagerId });
		currNotification.send(new set<string> { userInfo.getUserId() });
    }
}