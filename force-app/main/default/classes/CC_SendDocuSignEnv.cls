/**-------------------------------------------------------------------
 * Description : used to send docusign envelope
 * -------------------------------------------------------------------
 * History :
 * [23.OCT.2020] Prateek Kadkol - Code Creation
 * [23.AUG.2023] tdontha@aldar.com - ASF-1403
 * -------------------------------------------------------------------
 */
global without sharing class CC_SendDocuSignEnv  implements HexaBPM.iCustomCodeExecutable {
    
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR,HexaBPM__Step__c stp) {
        String templateId = null;
        if(Test.isRunningTest()) {
            templateId = SR.HexaBPM__SR_Template__c;
        } else {
            templateId = stp.HexaBPM__SR__r.HexaBPM__SR_Template__c;
        }

        string strResult = 'Success';
        boolean hasGenDoc = false;
        List<HexaBPM__SR_Doc__c> newSrDocsToInsert = new List<HexaBPM__SR_Doc__c>(); 
        list<string> exsistingDocsMasterCode = new list<string>();
        Map<string, string> docToSendMap = new Map<string, string>{'Digital Signature by Authorized Signatory' => 'Agency_Agreement_Document',
                                                                   'Digital Signature by Head of Broker Management' => 'AgencyAgreementSignedbyAgency'};
                                                                   //'Digital Signature by CCO'=>'AgencyAgreementSignedbyHeadofBM'}; Removed to Make Head of Broker Management final signing in SR
    
        for (HexaBPM__SR_Doc__c srDoc : [ SELECT id, HexaBPM__Document_Master__r.HexaBPM__Code__c,
                                        HexaBPM__SR_Template_Doc__r.HexaBPM__Generate_Document__c
                                        FROM HexaBPM__SR_Doc__c WHERE HexaBPM__Service_Request__c =:stp.HexaBPM__SR__c]) {
            exsistingDocsMasterCode.add(srDoc.HexaBPM__Document_Master__r.HexaBPM__Code__c);
        }
        
        // insert signed copy placeholderes
        for (HexaBPM__SR_Template_Docs__c srDocTemp : [SELECT Id,HexaBPM__Document_Master__c,HexaBPM__Document_Master__r.Name,
                                                       HexaBPM__Generate_Document__c,HexaBPM__Document_Master__r.HexaBPM__Code__c,
                                                       HexaBPM__Optional__c
                                                       FROM HexaBPM__SR_Template_Docs__c 
                                                       WHERE HexaBPM__Evaluated_at__c =:stp.HexaBPM__SR_Step__c AND 
                                                       HexaBPM__SR_Template__c =:templateId AND
                                                       HexaBPM__Added_through_Code__c = TRUE]) { //stp.HexaBPM__SR__r.HexaBPM__SR_Template__c
                                                           
            if(!exsistingDocsMasterCode.contains(srDocTemp.HexaBPM__Document_Master__r.HexaBPM__Code__c)){
                HexaBPM__SR_Doc__c srDoc = new HexaBPM__SR_Doc__c();
                if(srDocTemp.HexaBPM__Generate_Document__c == true){
                    hasGenDoc = true;
                    srDoc.HexaBPM__Sys_IsGenerated_Doc__c = true;
                    srDoc.HexaBPM__Generate_Document__c = true;
                    srDoc.Send_For_E_Signature__c = true;
                }
                
                srDoc.Name = srDocTemp.HexaBPM__Document_Master__r.Name ;
                srDoc.HexaBPM__Service_Request__c = stp.HexaBPM__SR__c;
                srDoc.HexaBPM__From_Finalize__c = true;
                srDoc.HexaBPM__Document_Master__c = srDocTemp.HexaBPM__Document_Master__c;
                srDoc.HexaBPM__SR_Template_Doc__c = srDocTemp.Id;
                srDoc.HexaBPM__Step__c = stp.Id;
                srDoc.HexaBPM__Is_Not_Required__c = srDocTemp.HexaBPM__Optional__c;	
                newSrDocsToInsert.add(srDoc);
            }                                         
        }
        if(newSrDocsToInsert.size() > 0){
          insert newSrDocsToInsert;
        }
        
        if(docToSendMap.containsKey(stp.Step_Template_Code__c) && hasGenDoc == false){
            //Tharun changed below logic:ASF-1403
            if(stp.HexaBPM__SR__r.HexaBPM__Record_Type_Name__c == ALD_Constants.Agency_Re_Registration_DEV_RT){
                AgencyRegDocuSignHelper.sendUsingDocuSignFuture(stp.HexaBPM__SR__c,stp.id,docToSendMap.get(stp.Step_Template_Code__c));
            }else{
                DocuSignHelper.sendUsingDocuSignFuture(stp.HexaBPM__SR__c,stp.id,docToSendMap.get(stp.Step_Template_Code__c));
            }
            //Tharun changed above logic:ASF-1403
        }
        return strResult;
    }
}