//Create Memo record and send for approval
@RestResource (urlMapping = '/insert/bookingmemo')
global with sharing class BookingMemoCreateWebservice {
    /*
    {
    "memoDetails":      {
                            "RelatedOpportunity__c":"0067E00000GqBK0",
                            "MemoType__c":"New Sale",
                            "MemoSubject__c":"New Sale",
                            "MemoHeader__c":"Header",
                            "SpecialNote__c":"Note"
                        },
    "unitDetails": [{
                        "unitId":  "a0e7E00000FrTq6",
                        "offerID":  "",
                        "paymentPlanId":  "",
                        "installmentLines" : [{
                                "Unit__c":"a0e7E00000FrTq6",
                                "PaymentPlan__c":"a0Q7E000004XqTk",
                                "ProposedInstallmentDate__c":"2022-09-09",
                                "Description__c":"Description",
                                "ProposedInstallmentPercentage__c":40,
                                "BrokerPayoutPercentage__c":40
                            },
                            {
                                "Unit__c":"a0e7E00000FrTq6",
                                "PaymentPlan__c":"a0Q7E000004XqTk",
                                "ProposedInstallmentDate__c":"2022-09-09",
                                "Description__c":"Description",
                                "ProposedInstallmentPercentage__c":40,
                                "BrokerPayoutPercentage__c":40
                            }],
                        "calculationWrapper":    {
                                "discountPercentage": 1,
                                "rebatePercentage": 0.00,
                                "scWaiverYears": 0,
                                "pmFeeYear": 0,
                                "homeMaintenanceYears": 0,
                                "ADMFeePercentage": 0.00,
                                "subsidyPercentage": 0.00,
                                "internalCommissionPercentage": 0.00,
                                "brokerCommissionPercentage": 0.00,
                                "selectedVoucher": "",
                                "selectedMembership": ""
                        }
                    }]
}
        
     
    */
    @HTTPPost
    global static void doPost(BookingMemo__c memoDetails, list<UnitDetails> unitDetails){
        RestContextHandler handler = new RestContextHandler(true);
        Savepoint savePoint = Database.setSavepoint();
        try {            
            if(memoDetails!=null){
                insert memoDetails;
                list<InstallmentLineChanges__c> installmentLinesToInsert = new list<InstallmentLineChanges__c>();
                list<MemoLines__c> memoLineToInsert = new list<MemoLines__c>();
                if(unitDetails!=null && !unitDetails.isEmpty()){
                    for(UnitDetails udRecord : UnitDetails){
                        if(udRecord.installmentLines!=null && !udRecord.installmentLines.isEmpty()){
                            Integer counterValue =0;
                            for(InstallmentLineChanges__c ilc : udRecord.installmentLines){
                                counterValue++;
                                ilc.BookingMemo__c = memoDetails.Id;
                                ilc.InstallmentNumber__c = counterValue;
                                installmentLinesToInsert.add(ilc);
                            }
                        }
                        
                        if(udRecord.calculationWrapper!=null){
                            if(udRecord.calculationWrapper.isValid){
                                MemoLines__c memoLine = new MemoLines__c();
                                memoLine.BookingMemo__c = memoDetails.Id;
                                memoLine.Unit__c =  udRecord.unitId;
                                memoLine.ExistingOffer__c=   udRecord.offerID;
                                memoLine.ExistingPaymentPlan__c=   udRecord.paymentPlanId;
                                memoLine.DiscountPercentage__c=   udRecord.calculationWrapper.discountPercentage ;
                                memoLine.RebatePercentage__c=  udRecord.calculationWrapper.rebatePercentage ;
                                memoLine.SCWaiverYears__c=  udRecord.calculationWrapper.scWaiverYears ;
                                memoLine.PMFeeYears__c=  udRecord.calculationWrapper.pmFeeYear ;
                                memoLine.HomeMaintenanceYears__c=  udRecord.calculationWrapper.homeMaintenanceYears ;
                                memoLine.ADMFeePercentage__c=  udRecord.calculationWrapper.ADMFeePercentage ;
                                memoLine.SubsidyPercentage__c=  udRecord.calculationWrapper.subsidyPercentage ;
        
                                memoLine.IntCommissionPercentage__c=  udRecord.calculationWrapper.internalCommissionPercentage ;
                                memoLine.BrokerCommissionPercentage__c=   udRecord.calculationWrapper.brokerCommissionPercentage;
                                memoLine.VoucherName__c=  udRecord.calculationWrapper.selectedVoucher ;
                                memoLine.VoucherAmount__c=  udRecord.calculationWrapper.voucherValue ;
                                memoLine.MembershipType__c=   udRecord.calculationWrapper.selectedMembership ;
                                memoLine.MembershipAmount__c=  udRecord.calculationWrapper.membershipValue ;
                                memoLineToInsert.add(memoLine);
        
                            }else{
                                throw new CustomException('Validation Error');
                            }
                        }
                        
                    }
                }
                if(!installmentLinesToInsert.isEmpty()){
                    insert installmentLinesToInsert;
                }
                if(!memoLineToInsert.isEmpty()){
                    insert memoLineToInsert;
                }
                // Submit for approval
                Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
                req1.setComments('Booking Memo Approval Request');
                req1.setObjectId(memoDetails.Id);
                req1.setSubmitterId(UserInfo.getUserId());
                req1.setProcessDefinitionNameOrId('BookingMemoApproval');
                req1.setSkipEntryCriteria(true);
                Approval.ProcessResult result = Approval.process(req1);
                
                /*if(installmentLines!=null && !installmentLines.isEmpty()){
                    for(InstallmentLineChanges__c installmentLineChanges : installmentLines){
                        installmentLineChanges.BookingMemo__c = memoDetails.Id;
                    }
                    insert installmentLines;
                }
                
                
                
                if(calculationWrapper!=null){
                    //Check Validation
                    if(calculationWrapper.isValid){
                        MemoLines__c memoLine = new MemoLines__c();
                        memoLine.BookingMemo__c = memoDetails.Id;
                        memoLine.Unit__c =  unitId;
                        memoLine.ExistingOffer__c=   offerID;
                        memoLine.ExistingPaymentPlan__c=   paymentPlanId;
                        memoLine.DiscountPercentage__c=   calculationWrapper.discountPercentage ;
                        memoLine.RebatePercentage__c=  calculationWrapper.rebatePercentage ;
                        memoLine.SCWaiverYears__c=  calculationWrapper.scWaiverYears ;
                        memoLine.PMFeeYears__c=  calculationWrapper.discountPercentage ;
                        memoLine.HomeMaintenanceYears__c=  calculationWrapper.homeMaintenanceYears ;
                        memoLine.ADMFeePercentage__c=  calculationWrapper.ADMFeePercentage ;
                        memoLine.SubsidyPercentage__c=  calculationWrapper.subsidyPercentage ;

                        memoLine.IntCommissionPercentage__c=  calculationWrapper.internalCommissionPercentage ;
                        memoLine.BrokerCommissionPercentage__c=   calculationWrapper.brokerCommissionPercentage;
                        memoLine.VoucherName__c=  calculationWrapper.selectedVoucher ;
                        memoLine.VoucherAmount__c=  calculationWrapper.voucherValue ;
                        memoLine.MembershipType__c=   calculationWrapper.selectedMembership ;
                        memoLine.MembershipAmount__c=  calculationWrapper.membershipValue ;
                        insert memoLine;

                        // Submit for approval
                        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
                        req1.setComments('Booking Memo Approval Request');
                        req1.setObjectId(memoDetails.Id);
                        req1.setSubmitterId(UserInfo.getUserId());
                        req1.setProcessDefinitionNameOrId('BookingMemoApproval');
                        req1.setSkipEntryCriteria(true);
                        Approval.ProcessResult result = Approval.process(req1);
                        //vals to return
                    }else{
                        throw new CustomException('Validation Error');
                    }
                   
                }*/
                
            }
            
            //Response setting
            handler.response.success = true;
            handler.response.data = memoDetails.Id;
            handler.finalize();
            
        } catch (Exception e) {
            Database.rollback(savePoint);
            System.debug('msg '+ e.getMessage());
            System.debug('line no '+e.getLineNumber());
             //Response setting
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = Constants.MESSAGE_GENERIC_ERROR;
            handler.finalize(e);
            
        }
    }
    
    global class UnitDetails {
        public Id unitId {get;set;}
        public Id offerID {get;set;}
        public Id paymentPlanId {get;set;}
        public list<InstallmentLineChanges__c> installmentLines {get;set;}
        public BookingMemoCalculateWebservice.MemoCalculationWrapper calculationWrapper {get;set;}
        public UnitDetails(){}
    }
    
}