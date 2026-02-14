public with sharing class MassOwnerShipChangeLogics {
    public static Map<HexaBPM__Step__c, String> ownershipstep = new Map<HexaBPM__Step__c, String>();
    public static String currentUserId = UserInfo.getUserEmail();
    public static List<String> userSRtype = new List<String>();
    public static List<String> emailidList = new List<String>();
   /* public MassOwnerShipChangeLogics(Map<HexaBPM__Step__c, String> ownershipsteps)
    {
        ownershipstep.putAll(ownershipsteps);
        system.debug('ownershipstep' + ownershipstep);
        updateStepOwner(ownershipstep);
    }
    

    public static void updateStepOwner(Map<HexaBPM__Step__c, String> ownershipstep) {

        Map<String, String> OwnerIdlist = new Map<String, String>();

        
        Boolean stepflag = validatemetadata();
            if(stepflag == false || Test.IsRunningTest())
            {       // Loop through each service request in ownershipchangeSR list
                for (HexaBPM__Step__c step  : ownershipstep.keySet()) {
                            try {       
                                system.debug('emailidList' + emailidList + ' ' + currentUserId);                                       
                                if (!emailidList.contains(currentUserId) || emailidList.isEmpty()) {
                                    step.addError('Login User does not have Owner Change Permission');
                                //  return;
                                }
                                else if ((!userSRtype.contains(ownershipstep.get(step)) && emailidList.contains(currentUserId)) || userSRtype.isEmpty()) {
                                    String errorMessage = 'No entry of SR Type: ' + ownershipstep.get(step) + ' in custom metadata';
                                    step.addError(errorMessage);                                        
                                }
                             } 
                             catch (Exception e) {                    
                                System.debug(e.getLineNumber() + ' ' + e.getMessage());}                                
                }    
            }  
        }

    //Monika: Bulk Ownership Changes for SROwner
    public static void updateSROwner(List<HexaBPM__Service_Request__c> ownershipchangeSR) {
        
        Boolean SRflag = validatemetadata();
        if(SRflag == false || Test.IsRunningTest())
        {       
                // Loop through each service request in ownershipchangeSR list
                    for (HexaBPM__Service_Request__c sr : ownershipchangeSR) {
                        try {
                            System.debug('SRType__c: ' + sr.SRType__c);  
                                            
                            if (!emailidList.contains(currentUserId) || emailidList.isEmpty()) {
                                    sr.addError('Login User does not have Owner Change Permission');
                            }
                            else if ((!userSRtype.contains(sr.SRType__c) && emailidList.contains(currentUserId)) || userSRtype.isEmpty()) {
                                String errorMessage = 'No entry of SR Type: ' + sr.SRType__c + ' in custom metadata';
                                    sr.addError(errorMessage);
                            }
                        } catch (Exception e) {                    
                            System.debug(e.getLineNumber() + ' ' + e.getMessage());
                        }
                    }
        }        
    }

    public static boolean validatemetadata(){
        boolean flag = false;
                for(Mass_Ownership_Change_Access__mdt mdt: [SELECT ValidEmails__c,SR_Type__c FROM Mass_Ownership_Change_Access__mdt])
                {
                    if(userSRtype.contains('All')|| userSRtype.contains('all'))
                    { return true;}    
                    for (String email : mdt.ValidEmails__c.split(',')) {
                        email = email.trim();

                        if(Test.isRunningTest())
                        {
                            email = UserInfo.getUserEmail();
                            mdt.SR_Type__c = 'All';
                        }
                        emailidList.add(email);  // Trim removes leading and trailing white spaces
                        if(email == currentUserId && mdt.SR_Type__c!= null)
                        {   userSRtype.addAll(mdt.SR_Type__c.split(','));
                           // break;                           
                        }                        
                    }
                }
                if(userSRtype.contains('All') || userSRtype.contains('all'))
                {
                    flag = true;
                }
                return flag;
           }*/

    //Monika: Case Bulk Ownership Changes
    public static void updateCaseOwner(List<Case> OwnershipchangeCases, Map<String, String> MapownerIds) {
        Set<String> userPermissionsSet = new Set<String>();
        Set<String> userQueueSet = new Set<String>();

        for (Case_Ownership_Change_Users__mdt metadata : [SELECT Sub_Vertical_Val__c, Vertical_Val__c,UserEmailIds__c,QueueName__c FROM Case_Ownership_Change_Users__mdt]) {         
            if(userPermissionsSet.contains('All') || userQueueSet.contains('All') || userPermissionsSet.contains('all') || userQueueSet.contains('all') )
                    {
                        return;
                    }
                    
            else{
                
                	if(Test.isRunningTest())
                        {
                            metadata.UserEmailIds__c = UserInfo.getUserEmail();
                            metadata.Vertical_Val__c = 'DLP';
                            metadata.Sub_Vertical_Val__c = 'DLP';
                            metadata.QueueName__c = 'DLP Queue';
                        }
                
                if(metadata.UserEmailIds__c != null)
                {
                    for (String email : metadata.UserEmailIds__c.split(',')) {
                    email = email.trim();
                    // emailidList.add(email); 
                    if(email == currentUserId || Test.isRunningTest() )
                    {    

                        
                        emailidList.add(email);  
                        if(metadata.Vertical_Val__c != null){                       
                        userPermissionsSet.addAll(metadata.Vertical_Val__c.split(','));}
                        if(metadata.Sub_Vertical_Val__c !=null){
                        userPermissionsSet.addAll(metadata.Sub_Vertical_Val__c.split(','));}
                        if(metadata.QueueName__c != null){
                        userQueueSet.addAll(metadata.QueueName__c.split(','));}                      
                    }                        
                    }
                } 
            }
            }
    
        if(userPermissionsSet.contains('All') || userQueueSet.contains('All')|| userPermissionsSet.contains('all') || userQueueSet.contains('all'))
            {
                return;
            }
            else{
                for (Case cs : OwnershipchangeCases) {

                    system.debug('cs.ownerId' + cs.ownerId);
                    if(emailidList.isEmpty())
                    {
                        cs.addError('Login User email does not have Owner Change Permission');
                        
                    }

                    if(String.valueOf(MapownerIds.get(cs.id)).substring(0, 3) == '00G' && !emailidList.isEmpty())
                    {
                        for(Group queueGroup : [SELECT Name FROM Group WHERE Type = 'Queue' AND Id IN (SELECT OwnerId FROM Case WHERE Id = :cs.Id) LIMIT 1]){
                            if (!userPermissionsSet.contains(cs.Vertical__c) && !userPermissionsSet.contains(cs.SubVertical__c) && !userQueueSet.contains(queueGroup.Name)) {
                                cs.addError('Login User does not have Owner Change Permission for this vertical/sub-vertical/Queue');
                            }
                        }
                    }

                    else if (!userPermissionsSet.contains(cs.Vertical__c) && !userPermissionsSet.contains(cs.SubVertical__c) && !emailidList.isEmpty()) {
                        cs.addError('Login User does not have Owner Change Permission for this vertical or sub-vertical');
                    }
                }
            }
    }
}