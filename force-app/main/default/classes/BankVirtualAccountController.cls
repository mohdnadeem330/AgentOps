public class BankVirtualAccountController {
    
    Public static String RequestPending              = 'Request Pending';
    Public static String Available                   = 'Available';
    Public static String Cancelled                   = 'Cancelled';
    Public static String Escrow                      = 'Escrow';
    Public static String AldarCorporate              = 'Aldar Corporate';
    Public static String BankIntegrationVA           = 'BankIntegrationVA';
    Public static String BankIntegrationVACancel     = 'BankIntegrationVACancel';
    Public static String FABBankIntegrationVA        = 'FABBankIntegrationVA';
    Public static String FABBankIntegrationVACancel  = 'FABBankIntegrationVACancel';
    Public static String FABBankIntegrationVAModify  = 'FABBankIntegrationVAModify';
    Public static String ADIBBankIntegrationVA       = 'ADIBBankIntegrationVA';
    Public static String ADIBBankIntegrationVACancel = 'ADIBBankIntegrationVACancel';
    Public static String ADIBBankIntegrationVAModify = 'ADIBBankIntegrationVAModify';
    Public static String ProjectObject               = 'Project__c';
    Public static String BuildingSectionObject       = 'BuildingSection__c';
    
    @AuraEnabled
    public static VAStatsWrapper getVirtualAccountStatistics(Id recordId){
        VAStatsWrapper wrapper = new VAStatsWrapper();
        Project__c project;
        BuildingSection__c buildingSection;
        String objectName = recordId.getSObjectType().getDescribe().getName();
        try{
            if(objectName == ProjectObject){
                project = getProjectDetails(recordId);
            }else if(objectName == BuildingSectionObject){
                buildingSection = getBuildingSectionDetails(recordId);
            }
            
            List<BankVirtualAccounts__c> bufferVAs = new List<BankVirtualAccounts__c>();
            List<BankVirtualAccounts__c> RequestedVAs = new List<BankVirtualAccounts__c>();
            List<BankVirtualAccounts__c> failedVAs = new List<BankVirtualAccounts__c>();
            List<BankVirtualAccounts__c> UsedVAs = new List<BankVirtualAccounts__c>();
            List<BankVirtualAccounts__c> CancelledVAs = new List<BankVirtualAccounts__c>();
            List<Unit__c> unitList    = new List<Unit__c>();
            List<BankVirtualAccounts__c> bankVirtualAccounts = [SELECT
                                                                Id,
                                                                BufferFlag__c,
                                                                Unit__c,
                                                                Project__c,
                                                                buildingSection__c,
                                                                StatusFlag__c,
                                                                ErrorReason__c,
                                                                VirtualAccountClosureDate__c
                                                                FROM BankVirtualAccounts__c 
                                                                WHERE (Project__c =: recordId OR buildingSection__c =: recordId)];
            
            unitList = [SELECT Id FROM Unit__c WHERE Project__c =: recordId];
            if(!bankVirtualAccounts.isEmpty()){
                for(BankVirtualAccounts__c bva: bankVirtualAccounts){
                    if(bva.BufferFlag__c && bva.Unit__c == null && bva.StatusFlag__c == Available){
                        bufferVAs.add(bva);
                    }
                    if(bva.StatusFlag__c == RequestPending && bva.ErrorReason__c == null){
                        RequestedVAs.add(bva);
                    }
                    if(bva.ErrorReason__c != null){
                        failedVAs.add(bva);
                    }
                    if(!bva.BufferFlag__c && bva.StatusFlag__c == Available){
                        UsedVAs.add(bva);
                    }
                    if(bva.VirtualAccountClosureDate__c != null &&  bva.StatusFlag__c == Cancelled){
                        CancelledVAs.add(bva);
                    }
                }
            }
            wrapper.TotalVA = bankVirtualAccounts.size();
            wrapper.TotalBufferVA = bufferVAs.size();
            wrapper.TotalRequestedVA = RequestedVAs.size();
            wrapper.TotalFailedVA = failedVAs.size();
            wrapper.TotalUsedVA = UsedVAs.size();
            wrapper.TotalNumberOfUnits = unitList.size();
            wrapper.CancelledVA = CancelledVAs.size();
            if(objectName == ProjectObject){
                wrapper.project = project;
                wrapper.isVAEnabled = project.VAEnabled__c;
            }else if(objectName == BuildingSectionObject){
                wrapper.BuildingSection = buildingSection;
                wrapper.isVAEnabled = buildingSection.VAEnabled__c;
            }
        }catch(Exception ex){
            throw new AuraHandledException(ex.getmessage());
        }
        system.debug('wrapper::'+wrapper);
        system.debug('wrapper json::'+JSON.serialize(wrapper));
        return wrapper;
    }
    
    @AuraEnabled
    public static VAStatsWrapper createVirtualAccounts(Id recordId, String bankName, Integer NumberOfVAs, boolean escrowVACheck, boolean corporateVACheck){
        VAStatsWrapper wrapper = new VAStatsWrapper();
        String objectName = recordId.getSObjectType().getDescribe().getName();
        Project__c project;
        BuildingSection__c buildingSection;
        
        String configName = getBankConfigName(BatchToCreateBankVirtualAccount.ADIB);
        ALD_Bank_Configuration__mdt bankConfig;
        if(configName != ''){
            bankConfig = ALD_Bank_Configuration__mdt.getInstance(configName);
        }
        
        try{
            List<BankVirtualAccounts__c> vAccToInsert = new List<BankVirtualAccounts__c>();
            if(objectName == ProjectObject){
                project = getProjectDetails(recordId);
            }else if(objectName == BuildingSectionObject){
                buildingSection = getBuildingSectionDetails(recordId);
            }
            
            string virtualAccountType;
            for(Integer i=0; i < NumberOfVAs; i++ ){
                BankVirtualAccounts__c bva = new BankVirtualAccounts__c ();
                bva.AccountType__c = ALD_Constants.BANK_COLLECTION;
                
                if(escrowVACheck){
                    virtualAccountType = Escrow;
                    if( objectName == ProjectObject){
                        bva.BankName__c =  project.BankNameEscrow__c;
                        bva.EscrowAccountNumber__c = project.AccountNumberEscrow__c;
                        bva.EscrowIBANAccountNumber__c = project.IBANNoEscrow__c;
                        bva.Project__c = project.Id;
                        bva.RootVA__c = project.VARootNumber__c;
                    } else if(objectName == BuildingSectionObject){
                        bva.BankName__c =  buildingSection.BankNameEscrow__c;
                        bva.EscrowAccountNumber__c = buildingSection.AccountNumberEscrow__c;
                        bva.EscrowIBANAccountNumber__c = buildingSection.IBANNoEscrow__c;
                        bva.BuildingSection__c = buildingSection.Id;
                        bva.RootVA__c = buildingSection.VARootNumber__c;
                    }
                } else if(corporateVACheck){
                    virtualAccountType = AldarCorporate;
                    if( objectName == ProjectObject){
                        bva.BankName__c = project.BankNameCorporate__c;
                        bva.EscrowAccountNumber__c = project.AccountNumberCorporate__c;
                        bva.EscrowIBANAccountNumber__c = project.IBANNoCorporate__c;
                        bva.Project__c = project.Id;
                        bva.RootVA__c = project.VARootNumber__c;
                    }else if(objectName == BuildingSectionObject){
                        bva.BankName__c = buildingSection.BankNameCorporate__c;
                        bva.EscrowAccountNumber__c = buildingSection.AccountNumberCorporate__c;
                        bva.EscrowIBANAccountNumber__c = buildingSection.IBANNoCorporate__c;
                        bva.BuildingSection__c = buildingSection.Id;
                        bva.RootVA__c = buildingSection.VARootNumber__c;
                    }
                } 
                bva.Virtual_Account_Type__c = virtualAccountType;
                bva.BufferFlag__c = true;
                bva.StatusFlag__c = RequestPending;
                //FAB-Code-Comments 
                /*if(bankName == BatchToCreateBankVirtualAccount.FAB){
                    bva.EntityIdentifier__c = System.label.FAB_EntityIdentifier;
                    bva.CustomerCode__c = System.label.FAB_CustomerCode; 
                    bva.ServiceCode__c =  System.label.FAB_ServiceCode;
                    bva.ServiceName__c = System.label.FAB_ServiceName;
                }*/
                vAccToInsert.add(bva);
            }
            
            if(!vAccToInsert.isEmpty()){
                insert vAccToInsert;
                BatchToCreateBankVirtualAccount batch = new BatchToCreateBankVirtualAccount(vAccToInsert, virtualAccountType, bankName);
                if(Test.isRunningTest()){
                    database.executeBatch(batch);
                }else { 
                    database.executeBatch(batch, 1);
                }
            }
            wrapper = getVirtualAccountStatistics(recordId);
        }catch(Exception ex){
            throw new AuraHandledException(ex.getmessage());
        }
        return wrapper;
    }
    
    public static Project__c getProjectDetails(String recordId){
        
        return [SELECT
                Id,
                AccountNumberCorporate__c,
                AccountNumberEscrow__c,
                BankNameEscrow__c,
                BankNameCorporate__c,
                IBANNoCorporate__c,
                IBANNoEscrow__c,
                BeneficiaryNameEscrow__c,
                BeneficiaryNameCorporate__c,
                VAEnabled__c,VARootNumber__c
                FROM Project__c
                WHERE Id =: recordId];
    }
    
    public static BuildingSection__c getBuildingSectionDetails(String recordId){
        return [SELECT
                Id,
                AccountNumberCorporate__c,
                AccountNumberEscrow__c,
                BankNameEscrow__c,
                BankNameCorporate__c,
                IBANNoCorporate__c,
                IBANNoEscrow__c,
                BeneficiaryNameEscrow__c,
                BeneficiaryNameCorporate__c,
                VAEnabled__c,VARootNumber__c
                FROM BuildingSection__c
                WHERE Id =: recordId];
    }
    
    @AuraEnabled
    public static void retryVACallout(String recordId, String bankName, Boolean escrowVACheck, Boolean corporateVACheck){
        String virtualAccountType;
        if(escrowVACheck){
            virtualAccountType = Escrow; 
        }else if(corporateVACheck){
            virtualAccountType = AldarCorporate;
        }
        List<BankVirtualAccounts__c> vAccToRetry = [SELECT
                                                    Id,
                                                    EscrowAccountNumber__c,
                                                    Project__c, 
                                                    Project__r.BankNameEscrow__c,
                                                    Unit__c,
                                                    Unit__r.Status__c,
                                                    BankName__c,
                                                    Virtual_Account_Type__c 
                                                    FROM BankVirtualAccounts__c
                                                    WHERE VirtualAccountNumber__c = null 
                                                    AND EscrowAccountNumber__c != null 
                                                    AND Virtual_Account_Type__c =: virtualAccountType
                                                    AND BankName__c =:bankName
                                                    AND (StatusFlag__c =: RequestPending 
                                                         OR ErrorCode__c != null)];
        
        BatchToCreateBankVirtualAccount batch = new BatchToCreateBankVirtualAccount(vAccToRetry, virtualAccountType, bankName);
        if(Test.isRunningTest()){
            database.executeBatch(batch);
        }else {
            database.executeBatch(batch, 1);
        }
    }
    
    public class VAStatsWrapper{
        @AuraEnabled public Integer TotalVA;
        @AuraEnabled public Integer TotalBufferVA;
        @AuraEnabled public Integer TotalRequestedVA;
        @AuraEnabled public Integer TotalFailedVA;
        @AuraEnabled public Integer TotalUsedVA;
        @AuraEnabled public Integer TotalNumberOfUnits;
        @AuraEnabled public Integer CancelledVA;
        @AuraEnabled public Boolean isVAEnabled;
        @AuraEnabled public Project__c Project;
        @AuraEnabled public BuildingSection__c BuildingSection;
    }
    /*ALL the BVA Responses must go here   */
    public static void updateBankVirtualAccountResponse(String json, String requestBody, String ProcessName){
        if(processName == BankIntegrationVA || processName == BankIntegrationVACancel){
            updateBankVirtualAccountResponseADCB(json, requestBody);
        }
        //FAB-Code-Comments
        /*else if(processName == FABBankIntegrationVA || processName == FABBankIntegrationVACancel || processName == FABBankIntegrationVAModify){
            updateBankVirtualAccountResponseFAB(json, requestBody, processName);
        }*/else if(processName == ADIBBankIntegrationVA || processName == ADIBBankIntegrationVACancel || processName == ADIBBankIntegrationVAModify){
            updateBankVirtualAccountResponseADIB(json, requestBody, processName);
        }
    }
    public static ALDVA_ADCB_ResponseWrapper parseADCBResponse(String json){
        return (ALDVA_ADCB_ResponseWrapper)System.JSON.deserialize(json, ALDVA_ADCB_ResponseWrapper.class);
    }
    //FAB-Code-Comments
    /*public static FAB_MandateResponseWrapper parseFABResponse(String json){
        return (FAB_MandateResponseWrapper)System.JSON.deserialize(json, FAB_MandateResponseWrapper.class);
    }*/
    public static ADIB_MandateResponseWrapper parseADIBResponse(String json){
        return (ADIB_MandateResponseWrapper)System.JSON.deserialize(json, ADIB_MandateResponseWrapper.class);
    } 
    public static void updateBankVirtualAccountResponseADIB(String json, String requestBody, String processName){
        try{
            system.debug('json::'+json);
            List<BankVirtualAccounts__c> bvaList = new List<BankVirtualAccounts__c>();
            ADIB_MandateResponseWrapper wrapper   = parseADIBResponse(json);
            system.debug('wrapper::'+wrapper);
            BankVirtualAccounts__c bva = new BankVirtualAccounts__c();
            
            bva.Id = wrapper.context.channelRefNumber.left(wrapper.context.channelRefNumber.length()-14);
            // bva.RequestJSON__c = requestBody;
            system.debug('wrapper::'+wrapper.context.errorCode);
            if(wrapper.context.errorCode != null && wrapper.context.errorMessage != null && wrapper.context.errorCode != '' && wrapper.context.errorMessage != ''){
                bva.ErrorCode__c   = wrapper.context.errorCode;
                bva.ErrorReason__c = wrapper.context.errorMessage;
                bvaList.add(bva);
            }else{
                if(processName == ADIBBankIntegrationVA){
                    //bva.CustomerCode__c = wrapper.context.customerCode;
                    //bva.CustomerID__c = wrapper.context.customerGuid;
                    bva.VirtualAccountNumber__c = wrapper.payload.rangeUpTo;
                    bva.VirtualIBANAccountNumber__c = wrapper.payload.vaIbanRangeUpto;
                    bva.StatusFlag__c = wrapper.context.status == 'SUCCESS' ? Available : '';
                    bva.VirtualAccountOpenDate__c = System.now();
                    bva.SyncStatus__c = Constants.STATUS_SYNCED;
                    bvaList.add(bva);
                }else if(processName == ADIBBankIntegrationVACancel){
                    bva.StatusFlag__c = wrapper.context.status == 'SUCCESS' ? Cancelled : '';
                    bva.VirtualAccountClosureDate__c = System.now();
                    bva.BufferFlag__c = false;
                    bva.SyncStatus__c = Constants.STATUS_SYNCED;
                    bvaList.add(bva);
                }else if(processName == ADIBBankIntegrationVAModify && wrapper.context.status == 'SUCCESS'){
                    bva.SendModificationRequest__c = FALSE;
                    bvaList.add(bva);
                }
            }
            
            system.debug('bvaList::'+bvaList);
            if(!bvaList.isEmpty()){
                upsert bvaList;
            }
        }catch(Exception ex) {
            loggerService.save(LoggerService.createApexLog(ex,'Update Virtual Account Exception','BankVirtualAccountController','updateBankVirtualAccountResponseADIB'));    
        } 
    }
    
    public static void  updateBankVirtualAccountResponseADCB(String json, String requestBody){
        try{
            List<BankVirtualAccounts__c> bvaList = new List<BankVirtualAccounts__c>();
            ALDVA_ADCB_ResponseWrapper wrapper   = parseADCBResponse(json);
            BankVirtualAccounts__c bva = new BankVirtualAccounts__c();
            bva.Id = wrapper.response.requestId;
            bva.RequestJSON__c = requestBody;
            if(wrapper.response.errorCode != null && wrapper.response.errorDescription != null){
                bva.ErrorCode__c   = wrapper.response.errorCode;
                bva.ErrorReason__c = wrapper.response.errorDescription;
            }else{
                bva.StatusFlag__c = wrapper.response.virtualAccountStatus == 'C' ? ALD_Constants.ALDVA_STATUS_CANCELLED : (wrapper.response.virtualAccountStatus == 'A' ? Available:'');
                bva.VirtualAccountNumber__c = wrapper.response.virtualAccountNumber;
                bva.ResponseId__c = wrapper.responseId;
                bva.PhysicalAccountTitle__c = wrapper.response.physicalAccountTitle;
                bva.CustomerID__c = wrapper.response.customerID;
                bva.VirtualCustomerID__c = wrapper.response.virtualCustomerID;
                bva.VirtualAccountTitle__c = wrapper.response.virtualAccountTitle;
                bva.VirtualIBANAccountNumber__c = wrapper.response.virtualIBAN;
                if(wrapper.response.virtualAccountOpenDate != null){
                    date vaOpendate = date.parse(wrapper.response.virtualAccountOpenDate);
                    dateTime vaOpendateTime = datetime.newInstance(vaOpendate, Time.newInstance(0,0,0,0));
                    bva.VirtualAccountOpenDate__c = vaOpendateTime;
                }
                if(wrapper.response.virtualAccountClosureDate != null){
                    date vaClosedate = date.parse(wrapper.response.virtualAccountClosureDate);
                    dateTime vaClosedateTime = datetime.newInstance(vaClosedate, Time.newInstance(0,0,0,0));
                    bva.VirtualAccountClosureDate__c = vaClosedateTime;
                }
                bva.SyncStatus__c = Constants.STATUS_SYNCED;
            }
            bvaList.add(bva);
            if(!bvaList.isEmpty()){
                update bvaList;
            }
        }catch(Exception ex) {
            loggerService.save(LoggerService.createApexLog(ex,'Update Virtual Account Exception','BankVirtualAccountController','updateBankVirtualAccountResponseADCB'));    
        } 
    }
    
    //FAB-Code-Comments
    /*public static void updateBankVirtualAccountResponseFAB(String json, String requestBody, string processName){
        try {
            System.debug('requestBody BVA:'+requestBody);
            System.debug('responseBody :'+json);
            List<BankVirtualAccounts__c> bvaList = new List<BankVirtualAccounts__c>();
            FAB_MandateResponseWrapper wrapper = parseFABResponse(json);
            System.debug('wrapper :'+wrapper);
            if(wrapper.serviceStatusCode == 'S' ){
                String resdate = wrapper.responseDateTime;
                if (wrapper.message.vaIBANList.size() <= 0) { return; }
                for (FAB_MandateResponseWrapper.cls_vaIBANList vaItem : wrapper.message.vaIBANList) {
                    System.debug('vaItem :'+vaItem);
                    BankVirtualAccounts__c bva = new BankVirtualAccounts__c();
                    bva.Id = vaItem.vaRequestId;
                   // bva.RequestJSON__c = '' + requestBody;
                    bva.ResponseJSON__c = '' + vaItem;
                    
                    if(vaItem != null && vaItem.errorCode != '000'){
                        bva.ErrorCode__c = String.valueOf(vaItem.errorCode);
                        bva.ErrorReason__c = vaItem.statusDescription;
                    }
                    if(processName ==FABBankIntegrationVA){
                        System.debug('FABBankIntegrationVA :'+FABBankIntegrationVA);
                        bva.VirtualAccountNumber__c = vaItem.virtualAccountNo;
                        bva.VirtualIBANAccountNumber__c = vaItem.vaIban;
                        bva.VirtualAccountOpenDate__c  = System.now();
                        bva.BufferFlag__c = true;
                        bva.StatusFlag__c = vaItem.statusCode == 'R' ? ALD_Constants.ALDVA_STATUS_CANCELLED : (vaItem.statusCode == 'A' ? ALD_Constants.ALDVA_STATUS_AVAILABLE : '');
                    } else if(processName ==FABBankIntegrationVACancel){
                        if(vaItem.statusDescription == 'Request accepted for Virtual Account Deactivation' && vaItem.statusCode == 'A'){
                          //  bva.StatusFlag__c = ALD_Constants.ALDVA_STATUS_CANCELLED;
                            bva.VirtualAccountClosureDate__c = System.now();
                            bva.BufferFlag__c = false;
                        }else {
                          //  bva.StatusFlag__c = '';
                        }
                    }else if(processName == BatchToModifyBankVirtualAccount.FABBankIntegrationVAModify && vaItem.statusDescription == 'Request accepted for Virtual Account Modify' && vaItem.statusCode == 'A'){
                        bva.SendModificationRequest__c = FALSE;
                    }
                    bvaList.add(bva);
                }
            } else {
                LoggerService.save(LoggerService.addApexServiceCalls('Update Virtual Account', 'BankVirtualAccountController','updateBankVirtualAccountResponseFAB', null, requestBody, null));   
            }
            System.debug('bvaList :'+bvaList);
            if(!bvaList.isEmpty()){
                update bvaList;
            }
        } catch (Exception ex) {
            LoggerService.save(LoggerService.createApexLog(ex,'Update Virtual Account Exception','BankVirtualAccountController','updateBankVirtualAccountResponseFAB'));    
        } 
    } */
    
    public static String getBankConfigName(String bankName){
        String configName; 
        switch on bankName {
            when 'Abu Dhabi Commercial Bank' {
                configName = 'Abu_Dhabi_Commercial_Bank';
            }when 'First Abu Dhabi Bank'{
                configName = 'First_Abu_Dhabi_Bank';
            }when 'Abu Dhabi Islamic Bank'{
                configName = 'Abu_Dhabi_Islamic_Bank';
            }when else {
                configName = '';
            }
        }
        return configName;
    }
    
}