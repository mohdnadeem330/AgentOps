public class CalloutToMulesoftForRealTimeSync {
    
    @InvocableMethod(label='Send Account to MuleSoft')
    public static List<Result> sendToMuleSoft(List<Id> recordIds) {
        if (recordIds == null || recordIds.isEmpty()) return new List<Result>();
        CalloutToMulesoftForRealTimeSync handler = new CalloutToMulesoftForRealTimeSync(recordIds.get(0));
        List<Result> responseResult = handler.prepareAndCallMuleSoft();
        
        return responseResult;
    }
    
    private Id accountId;
    
    public CalloutToMulesoftForRealTimeSync(Id accountId) {
        this.accountId = accountId;
    }
    
    public List<Result> prepareAndCallMuleSoft() {
        Account acc = [
            SELECT Id, ResidentStatus__pc, Nationality__pc, SourceofFunds__pc, BankCountry__c,
            AnnualIncome__pc, CountryofBirth__pc, RecordTypeId,
            Sanctioned__c, SanctioningReason__c, AdverseMedia__c, PEP__c, AccountNumber__c
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];
        
        Map<Id, SalesOrder__c> salesOrderMap = new Map<Id, SalesOrder__c>([
            SELECT Id, Sales_Type__c, Project_Id__c, SellingPrice__c, Account__c
            FROM SalesOrder__c
            WHERE Account__c = :accountId AND CreatedDate = TODAY
        ]);
        
        Map<String, Object> requestMap = new Map<String, Object>{
            'residentStatus' => acc.ResidentStatus__pc,
                'nationality' => acc.Nationality__pc,
                'sourceOfFunds' => acc.SourceofFunds__pc,
                'bankCountry' => acc.BankCountry__c,
                'annualIncome' => acc.AnnualIncome__pc,
                'countryOfBirth' => acc.CountryofBirth__pc,
                'recordTypeId' => acc.RecordTypeId,
                'sanctioned' => acc.Sanctioned__c,
                'sanctioningReason' => acc.SanctioningReason__c,
                'adverseMedia' => acc.AdverseMedia__c,
                'pep' => acc.PEP__c,
                'accountNumber' => acc.AccountNumber__c
                };
                    
        Map<Id, String> salesOrderTypeMap = getSalesOrderType(salesOrderMap.keySet());
        Map<Id, Map<String, Decimal>> installmentMap = getSalesOrderInstallmentData(salesOrderMap.keySet());
        List<Map<String, Object>> salesOrdersList = new List<Map<String, Object>>();
        // Group Joint_OwnersSalesOrder__c records by SalesOrder and Type
        Map<Id, List<Map<String, Object>>> jointOwnersMap = new Map<Id, List<Map<String, Object>>>();
        Map<Id, List<Map<String, Object>>> thirdPartyMap = new Map<Id, List<Map<String, Object>>>();
        
        List<JointOwner__c> jointOwnerRecords = [SELECT Id, SalesOrder__c, Account__c, SharePercentage__c, RelationshipType__c, Account__r.AnnualIncome__pc, Expected_Amount__c FROM JointOwner__c WHERE SalesOrder__c IN :salesOrderMap.keySet()];
        
        for (JointOwner__c record : jointOwnerRecords) {
            Map<String, Object> recordMap = new Map<String, Object>{
                'accountID' => record.Account__c,
                'annualIncome' => record.Account__r.AnnualIncome__pc,
                'expectedAmount' => record.Expected_Amount__c
            };
            
            if(!jointOwnersMap.containsKey(record.SalesOrder__c)) {
                jointOwnersMap.put(record.SalesOrder__c, new List<Map<String, Object>>());
            }

            jointOwnersMap.get(record.SalesOrder__c).add(recordMap);
        }

        List<Sales_Order_Relationship__c> thirdPartyRecords = [SELECT Id, SalesOrder__c, Account__c, Account__r.AnnualIncome__pc, Expected_amount__c FROM Sales_Order_Relationship__c WHERE SalesOrder__c IN :salesOrderMap.keySet()];
        
        for (Sales_Order_Relationship__c record : thirdPartyRecords) {
            Map<String, Object> recordMap = new Map<String, Object>{
                'accountID' => record.Account__c,
                'annualIncome' => record.Account__r.AnnualIncome__pc,
                'expectedAmount' => record.Expected_Amount__c
            };

            if(!thirdPartyMap.containsKey(record.SalesOrder__c)) {
                thirdPartyMap.put(record.SalesOrder__c, new List<Map<String, Object>>());
            }

            thirdPartyMap.get(record.SalesOrder__c).add(recordMap);
        }
        
        for (SalesOrder__c order : salesOrderMap.values()) {
            Decimal currentYearPayment = 0;
            Decimal currentYearDownpayment = 0;
            if (installmentMap.containsKey(order.Id)) {
                Map<String, Decimal> values = installmentMap.get(order.Id);
                currentYearPayment = values.get('currentYearPayment');
                currentYearDownpayment = values.get('currentYearDownpayment');
            }
            
            salesOrdersList.add(new Map<String, Object>{
                'salesOrderType' => salesOrderTypeMap.containsKey(order.Id) ? salesOrderTypeMap.get(order.Id) : '',
                    'project' => order.Project_Id__c,
                    'sellingPrice' => order.SellingPrice__c,
                    'currentYearPayment' => currentYearPayment,
                    'currentYearDownpayment' => currentYearDownpayment,
                    'salesorderId' => order.Id,
                    'jointOwners' => jointOwnersMap.containsKey(order.Id) ? jointOwnersMap.get(order.Id) : new List<Map<String, Object>>(),
                    'thirdPartyOwners' => thirdPartyMap.containsKey(order.Id) ? thirdPartyMap.get(order.Id) : new List<Map<String, Object>>()
                    });
        }
        
        requestMap.put('salesOrder', salesOrdersList);
        
        String requestBody = JSON.serialize(requestMap);
        System.debug('Request Body ' + JSON.serializePretty(requestMap));
        return calloutMuleSoft(requestBody, 'RealTimeSyncProcess', true);
    }
    
    private static Map<Id, String> getSalesOrderType(Set<Id> salesOrderIdSet) {
        Map<Id, String> resultMap = new Map<Id, String>();
        if (salesOrderIdSet == null || salesOrderIdSet.isEmpty()) return resultMap;
        
        for (AggregateResult ar : [
            SELECT SalesOrder__c salesOrderId, COUNT(Id) recordCount
            FROM JointOwner__c
            WHERE SalesOrder__c IN :salesOrderIdSet
            GROUP BY SalesOrder__c
        ]) {
            Id soId = (Id) ar.get('salesOrderId');
            Integer count = (Integer) ar.get('recordCount');
            resultMap.put(soId, count > 0 ? 'Joint Owner' : 'Individual');
        }
        
        // Ensure all orders have a type
        for (Id soId : salesOrderIdSet) {
            if (!resultMap.containsKey(soId)) {
                resultMap.put(soId, 'Individual');
            }
        }
        
        return resultMap;
    }
    
    private static Map<Id, Map<String, Decimal>> getSalesOrderInstallmentData(Set<Id> salesOrderIdSet) {
        Map<Id, Map<String, Decimal>> result = new Map<Id, Map<String, Decimal>>();
        if (salesOrderIdSet == null || salesOrderIdSet.isEmpty()) return result;
        
        Date today = Date.today();
        Date jan1 = Date.newInstance(today.year(), 1, 1);
        Date dec31 = Date.newInstance(today.year(), 12, 31);
        
        
        List<InstallmentLines__c> installments = [
            SELECT SalesOrder__c, InstallmentAmount__c, InstallmentDate__c, InstallmentNumber__c
            FROM InstallmentLines__c
            WHERE SalesOrder__c IN :salesOrderIdSet
            AND InstallmentDate__c >= :jan1 AND InstallmentDate__c <= :dec31
        ];
        
        for (InstallmentLines__c inst : installments) {
            Id soId = inst.SalesOrder__c;
            if (!result.containsKey(soId)) {
                result.put(soId, new Map<String, Decimal>{
                    'currentYearPayment' => 0,
                        'currentYearDownpayment' => 0
                        });
            }
            
            Map<String, Decimal> data = result.get(soId);
            data.put('currentYearPayment', data.get('currentYearPayment') + inst.InstallmentAmount__c);
            if (inst.InstallmentNumber__c == 1) {
                data.put('currentYearDownpayment', inst.InstallmentAmount__c);
            }
        }
        
        return result;
    }
    
    public List<Result> calloutMuleSoft(String requestBody, String processName, Boolean processResponse) {
        List<Result> results = new List<Result>();

        try {
            MuleSoftSetting__mdt mulesoftAPI = Utilities.getMuleSoftDetails(processName);
            Organization org = Utilities.getOrganizationDetails();
            Result res = new Result();
            String endPointURL = org.IsSandbox ? mulesoftAPI.SandboxURL__c : mulesoftAPI.ProductionURL__c;
            
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endPointURL);
            request.setMethod(mulesoftAPI.Method__c);
            request.setHeader('Content-Type', 'application/json');
            request.setHeader('client_secret', mulesoftAPI.APIKey__c);
            request.setHeader('client_id', mulesoftAPI.APIId__c);
            request.setTimeout(120000);
            request.setBody(requestBody);
            
            Http http = new Http();
            HttpResponse response = http.send(request);
            System.debug('**Response Body** ' + response.getBody());
            
            if (response.getStatusCode() == 201 && String.isNotBlank(response.getBody())) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                if (responseMap.containsKey('results') && responseMap.get('results') != null) {
                    updateAccountWithRiskData( (Map<String, Object>) responseMap.get('results'));
                    Map<String, Object> dataMap = (Map<String, Object>) responseMap.get('results');
                    res.success = true;

                    if(dataMap.containsKey('riskErrorReason') && dataMap.get('riskErrorReason') != null) {
                        res.errorMessage = (String) dataMap.get('riskErrorReason');
                        res.success = false;
                }
            }
            }

            res.response = response.getBody();
            results.add(res);

            return results;
            
        } catch (Exception e) {
            System.debug('MuleSoft Callout Error: ' + e.getMessage());
        }
        
        return results;
    }
    
    private void updateAccountWithRiskData(Map<String, Object> dataMap) {
        try {
            Account accUpdate = new Account(Id = accountId);
            
            if (dataMap.containsKey('riskScore') && dataMap.get('riskScore') != null) {
                accUpdate.Compliance_Risk_Score__c = Integer.valueOf(dataMap.get('riskScore'));
            } else {
                accUpdate.Compliance_Risk_Score__c = null;
            }
            
            if (dataMap.containsKey('riskLevel') && dataMap.get('riskLevel') != null) {
                accUpdate.Compliance_Risk_Level__c = (String) dataMap.get('riskLevel');
            } else {
                 accUpdate.Compliance_Risk_Level__c = null;
            }
            
            if (dataMap.containsKey('riskUpdateDateTime') && dataMap.get('riskUpdateDateTime') != null) {
                String rawDate = (String) dataMap.get('riskUpdateDateTime');
                
                // Remove timezone offset and fractional seconds
                if (rawDate.contains('+')) {
                    rawDate = rawDate.substring(0, rawDate.indexOf('+'));
                } else if (rawDate.contains('Z')) {
                    rawDate = rawDate.replace('Z', '');
                }
                
                // Remove fractional seconds if present
                if (rawDate.contains('.')) {
                    rawDate = rawDate.substring(0, rawDate.indexOf('.'));
                }
                
                rawDate = rawDate.replace('T', ' ');
                
                accUpdate.Compliance_Risk_Date_Time__c = DateTime.valueOf(rawDate);
            }

            
            if (dataMap.containsKey('riskErrorReason') && dataMap.get('riskErrorReason') != null) {
                accUpdate.Compliance_Risk_Error_Reason__c = (String) dataMap.get('riskErrorReason');
            } else {
                accUpdate.Compliance_Risk_Error_Reason__c = null;
            }
            update accUpdate;
            System.debug('Account updated successfully with compliance risk data.');
        } catch (Exception ex) {
            System.debug('Failed to update Account with compliance risk data: ' + ex.getMessage());
        }
    }

    public class Result {
        @InvocableVariable
        public Boolean success;
        
        @InvocableVariable
        public String response;

        @InvocableVariable
        public String errorMessage;
    }
}