public class DocuSignStatusController {
    
    public class envelopeWrapper{
        @AuraEnabled  public dfsle__EnvelopeStatus__c  envelope{get;set;}
        @AuraEnabled public String envelopeCompleteddate {get;set;}
        @AuraEnabled public String envelopeStatus {get;set;}
        @AuraEnabled public String envelopeStatusMsg {get;set;}
        @AuraEnabled public String envelopeIcon {get;set;}
        @AuraEnabled public String envelopeViewedRecipient {get;set;}
        @AuraEnabled  public List<recipientStatusWrapper> recipientStatusWrapper{get;set;}
    } 
    public class recipientStatusWrapper{
        @AuraEnabled  public dfsle__RecipientStatus__c recipient{get;set;}
        @AuraEnabled public String recipientStatus {get;set;}
        @AuraEnabled public String recipientStatusCompleteddtae {get;set;}
        @AuraEnabled public String recipientStatusMsg {get;set;}
        @AuraEnabled public String recipientIcon {get;set;}
    }
    @AuraEnabled(cacheable=false)
    public static List<envelopeWrapper> getdocuSignStatusActivityLine(String recordId){
        List<envelopeWrapper> envWrapperList = new List<envelopeWrapper>();
        List<dfsle__EnvelopeStatus__c> envelopeStatusList = [SELECT
                                                             dfsle__Completed__c,
                                                             dfsle__DocuSignId__c,
                                                             dfsle__EmailSubject__c,
                                                             dfsle__Expires__c,
                                                             dfsle__LastStatusUpdate__c,
                                                             dfsle__Reason__c,
                                                             dfsle__SenderEmail__c,
                                                             dfsle__SenderName__c,
                                                             dfsle__Sent__c,
                                                             dfsle__SourceId__c,
                                                             dfsle__Status__c,
                                                             dfsle__TimeToComplete__c,
                                                             Id,
                                                             Name,
                                                             (SELECT
                                                              dfsle__Completed__c,
                                                              dfsle__Email__c,
                                                              dfsle__EnvelopeStatus__c,
                                                              dfsle__LastStatusUpdate__c,
                                                              dfsle__Reason__c,
                                                              dfsle__RoutingOrder__c,
                                                              dfsle__Sent__c,
                                                              dfsle__Sequence__c,
                                                              dfsle__SourceId__c,
                                                              dfsle__Status__c,
                                                              dfsle__Type__c,
                                                              Id,Name FROM dfsle__Recipients__r ORDER BY dfsle__Sequence__c DESC)
                                                             FROM dfsle__EnvelopeStatus__c
                                                             WHERE dfsle__SourceId__c =: recordId ORDER BY createddate DESC];
        system.debug('envelopeStatusList::'+envelopeStatusList);
        if(!envelopeStatusList.isEmpty()){
            for(dfsle__EnvelopeStatus__c env: envelopeStatusList) {
                List<recipientStatusWrapper> recipientStatusWrapperList = new List<recipientStatusWrapper>();
                envelopeWrapper envWrap = new envelopeWrapper(); 
                
                envWrap.envelope = env;
                if(env.dfsle__Completed__c != null){ envWrap.envelopeCompleteddate = env.dfsle__Completed__c.format('MMMMM dd, yyyy EEEE');
                }
                //envWrap.recipientStatuses = env.dfsle__Recipients__r;
                if(env.dfsle__Status__c == 'Sent'){
                    envWrap.envelopeStatus= 'Sent for Signature'; 
                    envWrap.envelopeIcon='custom:custom105';
                    envWrap.envelopeStatusMsg = 'sent an envelope';
                }else if(env.dfsle__Status__c == 'Completed'){
                    envWrap.envelopeIcon='standard:task2';
                    envWrap.envelopeStatus= 'Signed';  
                    envWrap.envelopeStatusMsg = 'Envelope Completed';
                }else if(env.dfsle__Status__c == 'Delivered'){
                    envWrap.envelopeIcon='standard:task2';
                    envWrap.envelopeStatus= 'Envelope Viewed';
                    envWrap.envelopeStatusMsg = 'has viewed the envelope';
                    envWrap.envelopeViewedRecipient = env.dfsle__Recipients__r.size()>0 ?  env.dfsle__Recipients__r[0].Name : 'Recipient';
                }else if(env.dfsle__Status__c == 'Voided'){
                    envWrap.envelopeIcon='standard:first_non_empty';
                    envWrap.envelopeStatus= 'Voided';
                    envWrap.envelopeStatusMsg = '';
                }else if(env.dfsle__Status__c == 'Declined'){
                    envWrap.envelopeIcon='standard:first_non_empty';
                    envWrap.envelopeStatus= 'Declined';
                    envWrap.envelopeStatusMsg = '';
                    
                }
                for(dfsle__RecipientStatus__c recipientStatus: env.dfsle__Recipients__r){
                    recipientStatusWrapper recipientStatusWrap = new recipientStatusWrapper();
                    recipientStatusWrap.recipient = recipientStatus;
                    if(recipientStatus.dfsle__Status__c == 'Sent'){
                        recipientStatusWrap.recipientStatus = 'Sent';
                        recipientStatusWrap.recipientStatusMsg = ' will receive the envelope soon';
                        recipientStatusWrap.recipientIcon = 'custom:custom105';
                        
                    }else if(recipientStatus.dfsle__Status__c == 'Created'){
                        recipientStatusWrap.recipientStatus = 'Created';
                        recipientStatusWrap.recipientStatusMsg = ' is queued to receive the envelope';
                        recipientStatusWrap.recipientIcon = 'utility:record_create';
                    }else if(recipientStatus.dfsle__Status__c == 'Completed'){
                        recipientStatusWrap.recipientStatus = 'Completed';
                        recipientStatusWrap.recipientStatusMsg = ' has completed the envelope';
                        recipientStatusWrap.recipientIcon = 'standard:task2';
                    }else if(recipientStatus.dfsle__Status__c == 'Delivered'){
                        recipientStatusWrap.recipientStatus = 'Viewed';
                        recipientStatusWrap.recipientStatusMsg = ' has viewed the envelope';
                        recipientStatusWrap.recipientIcon = 'custom:custom105';
                    }
                    if(recipientStatus.dfsle__Completed__c != null){
                        recipientStatusWrap.recipientStatusCompleteddtae = recipientStatus.dfsle__Completed__c.format('MMM dd, yyyy hh:mm a');
                    }
                    recipientStatusWrapperList.add(recipientStatusWrap);
                }
                envWrap.recipientStatusWrapper = recipientStatusWrapperList;
                envWrapperList.add(envWrap);
            }
            
        }
        return envWrapperList;
    }
}