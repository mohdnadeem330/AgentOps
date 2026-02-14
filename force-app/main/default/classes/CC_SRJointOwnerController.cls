/*
* Purpose: To modify the Joint Owner like (Add, Delete or Ownership Change with Primary Owner).
* SR Type: Addition Joint Owner, Deletion Joint Owner and Ownership Change
*/
global without sharing class CC_SRJointOwnerController implements HexaBPM.iCustomCodeExecutable {
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp) {
        try {
            HexaBPM__Service_Request__c serviceRequest = ServiceRequestService.queryAllFieldsWithExtraFields(new List<Id>{stp.HexaBPM__SR__c})[0];
            SalesOrder__c salesOrder = SalesOrderService.queryAllFieldsWithExtraFields(new List<Id>{serviceRequest.SalesOrder__c})[0];
            
            Map<Id, Id> joMap = new Map<Id, Id>();
            if (serviceRequest.SRType__c != Constants.ADDITION_JOINT_OWNER_RT) {
                for (JointOwner__c jointOwner: salesOrder.Joint_OwnersSalesOrder__r) {
                    joMap.put(jointOwner.Account__c, jointOwner.Id);
                }
            }

            System.debug('serviceRequest.SRType__c>>>' + serviceRequest.SRType__c);
            String soAccountId = salesOrder.Account__c, joAccountId = '';
            
            List<JointOwner__c> newJointOwnerList = new List<JointOwner__c>();
            List<JointOwner__c> updateJointOwnerList = new List<JointOwner__c>();
            List<JointOwnerHistory__c> jointOwnerHistoryList = new List<JointOwnerHistory__c>();
            List<SalesOrderOtherCharges__c> soOtherChargeList = new List<SalesOrderOtherCharges__c>();
            JointOwner__c newPrimaryJointOwner = new JointOwner__c();
            Boolean isNewPrimary = false;
            Decimal oldPrimaryOwnerPercentage = 0, newPrimaryOwnerPercentage = 0;

            for (AgencyTeam__c agencyTeam: serviceRequest.Partners__r) {
                if (agencyTeam.RelationshipType__c == agencyTeam.Description__c && agencyTeam.RelationshipType__c == Constants.PRIMARY_OWNER) {
                    newPrimaryOwnerPercentage = agencyTeam.ShareHoldingPercentage__c;
                    continue;
                } else if (agencyTeam.RelationshipType__c == Constants.PRIMARY_OWNER && agencyTeam.Description__c != Constants.PRIMARY_OWNER) {
                    oldPrimaryOwnerPercentage = agencyTeam.ShareHoldingPercentage__c;
                    continue;
                }
                JointOwner__c newJointOwner = new JointOwner__c();
                if (agencyTeam.JointOwner__c != null) {
                    newJointOwner.Id = agencyTeam.JointOwner__c;
                } else {
                    SalesOrderOtherCharges__c otherCharge = SRUtility.createSalesOrderOtherChargeFromSO(salesOrder, Constants.BUDGET_LINE_ADMFEE, '', (salesOrder.AmountPayable__c * 0.02 * (agencyTeam.ShareHoldingPercentage__c / 100)).setScale(2), serviceRequest);
                    otherCharge.Account__c = agencyTeam.Account__c;
                    soOtherChargeList.add(otherCharge);
                }
                newJointOwner.RelationshipType__c = agencyTeam.RelationshipType__c;
                newJointOwner.Account__c = agencyTeam.Account__c;
                if (agencyTeam.ShareHoldingPercentage__c == 0) {
                    newJointOwner.IsDeleted__c = true;

                    JointOwnerHistory__c jointOwnerHistory = new JointOwnerHistory__c();
                    jointOwnerHistory.PrimaryAccount__c = salesOrder.Account__c;
                    jointOwnerHistory.Account__c = agencyTeam.Account__c;
                    jointOwnerHistory.SalesOrder__c = salesOrder.Id;
                    jointOwnerHistory.RelationshipType__c = agencyTeam.RelationshipType__c;
                    jointOwnerHistory.SharePercentage__c = agencyTeam.ShareHoldingPercentage__c;
                    jointOwnerHistoryList.add(jointOwnerHistory);
                } else {
                    newJointOwner.SharePercentage__c = agencyTeam.ShareHoldingPercentage__c;
                }
                newJointOwner.SalesOrder__c = serviceRequest.SalesOrder__c;
                if (agencyTeam.Description__c == Constants.PRIMARY_OWNER && agencyTeam.RelationshipType__c != Constants.PRIMARY_OWNER) {
                    newPrimaryOwnerPercentage = agencyTeam.ShareHoldingPercentage__c;
                    newPrimaryJointOwner = newJointOwner;
                    joAccountId = newJointOwner.Account__c;
                    isNewPrimary = true;
                } else {
                    if (newJointOwner.Id != null) {
                        updateJointOwnerList.add(newJointOwner);
                    } else {
                        newJointOwnerList.add(newJointOwner);
                    }
                }
            }
            if (serviceRequest.ChargeCollected__c != null && serviceRequest.ChargeCollected__c != 0 && serviceRequest.ChargeWaivedOff__c == false) {
                SalesOrderOtherCharges__c otherCharge = SRUtility.createSalesOrderOtherCharge(serviceRequest, Constants.OTHER_CHARGES_TYPE_OWNERSHIP_CHANGE);
                // soOtherChargeList.add(otherCharge);
            }
            if (!soOtherChargeList.isEmpty()) {
                System.debug('soOtherChargeList>>>' + soOtherChargeList);
                insert soOtherChargeList;
            }
            if(!jointOwnerHistoryList.isEmpty()) {
                insert jointOwnerHistoryList;
            }
            if (isNewPrimary) {
                newPrimaryJointOwner.SharePercentage__c = oldPrimaryOwnerPercentage;
                newPrimaryJointOwner.Account__c = soAccountId;
                if (newPrimaryJointOwner.Id != null) {
                    updateJointOwnerList.add(newPrimaryJointOwner);
                } else {
                    newJointOwnerList.add(newPrimaryJointOwner);
                }
            }

            
            
            if (String.isNotBlank(joAccountId)) {
               // system.debug('Test AccId' +joAccountId);
                salesOrder.Account__c= joAccountId;
                Account acc = [Select IsPersonAccount,PersonContactId,(Select id from contacts) from Account where id = :joAccountId];
                if(acc.IsPersonAccount && acc.PersonContactId!=null){
                    system.debug('joAccountId.PersonContactId'+acc.PersonContactId);
                    salesOrder.Contact__c =acc.PersonContactId; 
                }
                if(!acc.IsPersonAccount && !acc.Contacts.isEmpty()){
                    system.debug('joAccountId.PersonContactId'+acc.PersonContactId);
                    salesOrder.Contact__c =acc.Contacts[0].id; 
                }
            }
            salesOrder.OwnerSharePercentage__c = newPrimaryOwnerPercentage;
            update salesOrder;
            
            if (!updateJointOwnerList.isEmpty()) {
                System.debug('updateJointOwnerList>>>' + updateJointOwnerList);
                update updateJointOwnerList;
            }
            if (!newJointOwnerList.isEmpty()) {
                System.debug('newJointOwnerList>>>' + newJointOwnerList);
                insert newJointOwnerList;
            }

            JointOwnerR2CalloutHelper.getDataForCallout(new List<Id>{stp.HexaBPM__SR__c});
        } catch (Exception ex) {
            System.debug('Error>>>'+ ex.getMessage() + ' | Line>>>' + ex.getLineNumber());
            return ex.getMessage();
        }
        return Constants.SUCCESS_RETURN_MESSAGE;
    }
}