/**********************************************************************************************************************
* Name               : SalesOrderSubStatusController                                                        
* Description        : This class is used as controller for LWC (salesOrderSubStatus)
* Usage              : salesOrderSubStatus LWC                                                          
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           paras.bhatt@pwc.com     21 Apr 2022      Initial Draft       
******************************************************************************************************************/
public with sharing class SalesOrderSubStatusController{
    
    /**
    * getApplicableSubStatus 
    *
    * return applicable sub status values based on SalesOrderOwnerChange__mdt
    * 
    *
    * @param recordID
    * @return   list<map<String,string>>  list of select options 
    * 
    */
    @AuraEnabled(cacheable=false)
    public static list<map<String,string>> getApplicableSubStatus(Id recordId){
        list<map<String,string>> mapToReturn = new list<map<String,string>>();
        list<SalesOrder__c> soRecord = [select id,Owner.Name,SubStatus__c from SalesOrder__c where id = :recordID ];
        if(!soRecord.isEmpty()){
            list<SalesOrderOwnerChange__mdt> relatedMetaRecords= [select id,masterLabel,NextApplicableStatus__c from SalesOrderOwnerChange__mdt where masterLabel = :soRecord[0].SubStatus__c ];
            if(!relatedMetaRecords.isEmpty() && relatedMetaRecords[0].NextApplicableStatus__c != null && relatedMetaRecords[0].NextApplicableStatus__c !=''){
                //Default allowed Transactions
                for(String tempVal : relatedMetaRecords[0].NextApplicableStatus__c.split(',') ){
                    map<string,string> tempMap=new map<string,string>();
                    tempMap.put('label',tempVal);
                    tempMap.put('value',tempVal);
                    mapToReturn.add(tempMap);
                }
                
            }
        }
        return mapToReturn;
    }

/**
* getSARejectionReason 
*
* return SalesOrder__c level SalesAdminRejectionReason__c picklist values
* 
*
* @param none
* @return  list<map<String,string>> SalesOrder__c.SalesAdminRejectionReason__c picklist Values
* 
*/
@AuraEnabled(cacheable=true)
public static list<map<String,string>> getSARejectionReason(){
    list<map<String,string>> picklistToReturn = new list<map<String,string>>();
    Schema.DescribeFieldResult fieldResult = SalesOrder__c.SalesAdminRejectionReason__c.getDescribe();
    for(Schema.PicklistEntry tempVal: fieldResult.getPicklistValues()){
        map<string,string> tempMap=new map<string,string>();
        tempMap.put('label',tempVal.getLabel());
        tempMap.put('value',tempVal.getValue());
        picklistToReturn.add(tempMap);
    }
    return picklistToReturn;
}

/**
* getLegalSubmissionReason 
*
* return SalesOrder__c level LegalSubmissionReason__c picklist values
* 
*
* @param none
* @return  list<map<String,string>> SalesOrder__c.LegalSubmissionReason__c picklist Values
* 
*/
@AuraEnabled(cacheable=true)
public static list<map<String,string>> getLegalSubmissionReason(){
    list<map<String,string>> picklistToReturn = new list<map<String,string>>();
    Schema.DescribeFieldResult fieldResult = SalesOrder__c.LegalSubmissionReason__c.getDescribe();
    for(Schema.PicklistEntry tempVal: fieldResult.getPicklistValues()){
        map<string,string> tempMap=new map<string,string>();
        tempMap.put('label',tempVal.getLabel());
        tempMap.put('value',tempVal.getValue());
        picklistToReturn.add(tempMap);
    }
    return picklistToReturn;
}
    
    /**
    * saveSubStatus 
    *
    * save the sub status value on record
    * 
    * @usage salesOrderSubStatus LWC
    *
    * @param recordID SalesOrder record ID
    * @param subStatusVal new SubStatus Value
    * @param legalReason Submit to leagal reason
    * @param SAReason Sales Admin rejection reason
    * @param remarks    remarks
    * @return   string  save resumt default should be SUccess
    * 
    */
    @AuraEnabled(cacheable=false)
    public static string saveSubStatus(Id recordID, string subStatusVal ,string legalReason,string SAReason,string remarks){
      //  Try{
        string messageToReturn = Constants.SUCCESS_MESSAGE;
        list<SalesOrder__c> soRecord = [select id,RecordType.Name,SubStatusRemarks__c,Name,OwnerID,Owner.Name,MortgageApplicable__c,SubStatus__c,SalesManager__c,SalesManager__r.Team__c,SalesAdminUser__c,CMUser__c,status__c from SalesOrder__c where id = :recordID ];
        //Populate the current user
       
        if(!soRecord.isEmpty()){
            

            if(subStatusVal == Constants.SALES_SUB_STATUS_SPA_SIGNEDOFF_PENDING && soRecord[0].status__c != Constants.SALES_STATUS && soRecord[0].RecordType.Name !=Constants.SO_RECORD_TYPE_RTO ){
                return 'Sales Order must have \''+Constants.SALES_STATUS+'\' status to perform this action.';
            }
            if(subStatusVal == Constants.SALES_SUB_STATUS_SPA_SIGNEDOFF_PENDING && soRecord[0].status__c != Constants.SO_STATUS_RTO_Approve_PENDING && soRecord[0].RecordType.Name ==Constants.SO_RECORD_TYPE_RTO ){
                return 'Sales Order must have \''+Constants.SALES_STATUS+'\' status to perform this action.';
            }
            //appending comments
            User currentUser = Utilities.getLoggedInUserDetail();
            if(remarks!=null && remarks!=''){
                soRecord[0].SubStatusRemarks__c=currentUser.Name +' ('+currentUser.Profile.Name+') '+System.now().format()+'\n ----- \n' +remarks +'\n\n'+ (soRecord[0].SubStatusRemarks__c==null?'':soRecord[0].SubStatusRemarks__c) ;
            }
            
            //Populate the current user
            list<SalesOrderOwnerChange__mdt> relatedMetaRecords= [select id,masterLabel,Owner__c,OwnerType__c,LocationBasedQueue__c,RelatedOwner__c from SalesOrderOwnerChange__mdt where masterLabel = :soRecord[0].SubStatus__c and RelatedOwner__c!=null];
            if(!relatedMetaRecords.isEmpty() && soRecord[0].get(relatedMetaRecords[0].RelatedOwner__c)==null ){
                soRecord[0].put(relatedMetaRecords[0].RelatedOwner__c,userInfo.getUserId());
            }
            //Updte baed on new record
            relatedMetaRecords= [select id,masterLabel,Owner__c,OwnerType__c,LocationBasedQueue__c,RelatedOwner__c from SalesOrderOwnerChange__mdt where masterLabel = :subStatusVal];
            soRecord[0].SubStatus__c = subStatusVal;//(soRecord[0].MortgageApplicable__c ==Constants.YES && subStatusVal == Constants.SALES_SUB_STATUS_SPA_SIGNEDOFF)? Constants.SALES_SUB_STATUS_REGISTRATION_PENDING :subStatusVal;
            if(legalReason!=null && legalReason !=''){
                soRecord[0].LegalSubmissionReason__c = legalReason;
            }
            if(SAReason!=null && SAReason!=''){
                soRecord[0].SalesAdminRejectionReason__c = SAReason;
            }
            Id newOwnerId;
            
            if(!relatedMetaRecords.isEmpty()){
                //Check new owner based on configuration
                if(relatedMetaRecords[0].Owner__c !=null && relatedMetaRecords[0].Owner__c !=''){
                    if(relatedMetaRecords[0].OwnerType__c.equalsIgnoreCase('Field API Name') && soRecord[0].get(relatedMetaRecords[0].Owner__c) !=null ){
                        newOwnerId = (ID)soRecord[0].get(relatedMetaRecords[0].Owner__c);
                    }else if(relatedMetaRecords[0].OwnerType__c.equalsIgnoreCase('Queue') ){
                        //try populating related user
                        if(relatedMetaRecords[0].RelatedOwner__c!=null && soRecord[0].get(relatedMetaRecords[0].RelatedOwner__c)!=null ){
                            if(relatedMetaRecords[0].RelatedOwner__c == 'CMUser__c'){
                                List<User> cmUser = [SELECT Id from user WHERE Id =:(ID)soRecord[0].get(relatedMetaRecords[0].RelatedOwner__c) AND isActive= true];
                                if(cmUser.size()>0){
                                    newOwnerId = cmUser[0].id ;
                                }
                            }else{
                                newOwnerId=(ID)soRecord[0].get(relatedMetaRecords[0].RelatedOwner__c);
                            }
                        }else{
                            String QueueNameToQuery = relatedMetaRecords[0].Owner__c;
                            if(relatedMetaRecords[0].LocationBasedQueue__c!=null && relatedMetaRecords[0].LocationBasedQueue__c && soRecord[0].SalesManager__r.Team__c !=null && soRecord[0].SalesManager__r.Team__c!='' ){
                                QueueNameToQuery = QueueNameToQuery +' '+ soRecord[0].SalesManager__r.Team__c;
                            }
                            for(Group tempGroup : [select Id,name from Group where Type = 'Queue' and name = :QueueNameToQuery]){
                                newOwnerId = tempGroup.id;  
                            }
                        }
                        
                    }else if(relatedMetaRecords[0].OwnerType__c.equalsIgnoreCase('User')){
                        if(relatedMetaRecords[0].Owner__c.equalsIgnoreCase('Current User')){
                            newOwnerId = currentUser.Id;
                        }else{
                            List<User> userList = [select Id from user where username= :relatedMetaRecords[0].Owner__c and isActive= true limit 1];
                            newOwnerId = !userList.isEmpty() ? userList[0].Id : currentUser.Id;
                        } 
                      }
                }
                system.debug('newOwnerId::'+newOwnerId);
                if(newOwnerId!=null && soRecord[0].OwnerID != newOwnerId){
                    //Update owner fiwelds
                    soRecord[0].OwnerID = newOwnerId;
                    soRecord[0].OwnershipChangeTime__c=system.now();
                    //trigger notification
                    // Create a new custom notification
                    
                    list<CustomNotificationType> notificationTypes = [SELECT Id, DeveloperName FROM CustomNotificationType where DeveloperName='SalesOrderOwnerChange']; 
                    if(!notificationTypes.isEmpty()){
                        Messaging.CustomNotification notification = new Messaging.CustomNotification();
                        // Set the contents for the notification
                        notification.setTitle('Sales Order Assignment');
                        notification.setBody('New Sales Order '+soRecord[0].Name +' assigned to you.' );

                        // Set the notification type and target
                        notification.setNotificationTypeId(notificationTypes[0].Id);
                        notification.setTargetId(soRecord[0].Id);
                        notification.send(new set<string> { newOwnerId } );
                    }
                    
                }
            }
            
            update soRecord;

        }
        return messageToReturn;
       /* }catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        } */
    }

   // public static void triggerOwnerNotificartion(Id recordID, string subStatusVal){

}