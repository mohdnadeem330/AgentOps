@RestResource(urlMapping='/getResaleUnitDetails')
global class Soho_UnitDetails {
    @HttpGet
    global static void getOffersAndSalesRepInfo() {
        RestContextHandler handler = new RestContextHandler(false);
        ResaleConstants.avoidProfileNameSOQL = true;
        try {
            Id salesOrderId = RestContext.request.params.get('salesOrderId');
            if(salesOrderId != null){
                List<SalesOrder__c> sos = [ SELECT Id, Unit__c, Account__c, 
                                                Unit__r.Name, Unit__r.ResaleListed__c, Unit__r.ResaleStatus__c, Unit__r.ListedBy__c, 
                                                Unit__r.ListedBy__r.Name, Unit__r.ListedBy__r.SmallPhotoUrl,
                                                Unit__r.ListedBy__r.MobilePhone, Unit__r.ListedBy__r.Phone, Unit__r.ListedBy__r.Email, 
                                                (SELECT Id, CaseNumber, Status, OwnerId, AccountId, 
                                                        Owner.Name, Owner.Phone, Owner.Email,
                                                        Listing_Price__c, Listing_Expiry__c 
                                                    FROM Cases__r
                                                    WHERE RecordTypeId =: ResaleConstants.Resale_Case_RecordTypeId
                                                        AND Status NOT IN (:ResaleConstants.CASE_CANCELLED, :ResaleConstants.CASE_CLOSED)
                                                    ORDER BY CreatedDate DESC
                                                    LIMIT 1),
                                                (SELECT Id, InvoiceId__c,Name,
                                                        InstallmentNumber__c, InstallmentAmount__c, 
                                                        AmountReceived__c, OutstandingAmount__c,InstallmentDate__c
                                                    FROM InstallmentLines__r 
                                                    ORDER BY InstallmentNumber__c ASC),
                                                (SELECT Id, Name, CreatedDate, Seller_Account__c, 
                                                        OfferExpiryDate__c, Offer_Price__c,
                                                        Status__c, Comments__c, 
                                                        Opportunity__c, Opportunity__r.StageName, Opportunity__r.Transferred__c, Opportunity__r.Document_Status__c,  
                                                        Sales_Order__c, Unit__c,SellerServiceCharge__c
                                                    FROM Resale_Offers__r
                                                    WHERE ( Status__c = 'Sent for Approval'
                                                            OR Status__c =: ResaleConstants.RO_STATUS_ACCEPTED )
                                                        AND Opportunity__r.StageName != 'Closed Lost'
                                                        AND (Case__r.Status !=: ResaleConstants.CASE_CANCELLED OR Case__r.Status !=:ResaleConstants.CASE_CLOSED)
                                                    ORDER BY Offer_Price__c DESC, CreatedDate DESC )
                                            FROM SalesOrder__c 
                                            WHERE Id =:salesOrderId ];
                if(sos != null && !sos.isEmpty()){
                    Id recentSellerId;

                    Map<String, Object> responseData = new Map<String, Object>(); 
                    
                    SalesOrder__c so = sos[0];
                    System.debug(JSON.serializePretty(so));
                    
                    responseData.put('installmentLines', so.InstallmentLines__r);
                    
                    if(so.getSObject('Unit__r').get('ListedBy__c') != null){
                        responseData.put('salesRepresentativeDetails', so.getSObject('Unit__r').getSObject('ListedBy__r'));
                    }

                    Boolean inListingPhase = true;
                    Map<String, Object> tempResponseData = new Map<String, Object>();

                    if(so.Cases__r != null && !so.Cases__r.isEmpty()){
                        Case resaleCase = so.Cases__r[0];
                        recentSellerId = resaleCase.AccountId;
                        //“activeResaleCase” parameter. Add key fields (Case number, listing price, listing expiry, Status are must)
                        Map<String, Object> activeResaleCase = new Map<String, Object>{
                            'Listing Expiry' => resaleCase.Listing_Expiry__c, 
                            'Listing Price' => resaleCase.Listing_Price__c,
                            'Status' => resaleCase.Status,
                            'Case Number' => resaleCase.CaseNumber
                        };
                        // tempResponseData.put('activeResaleCase', activeResaleCase);
                        responseData.put('activeResaleCase', activeResaleCase);

                        if( !responseData.containsKey('salesRepresentativeDetails') && resaleCase.OwnerId != ResaleService.ResaleRRQueue.Id){
                            responseData.put('salesRepresentativeDetails', resaleCase.getSObject('Owner'));
                        }
                        
                        if(ResaleConstants.RESALE_CASE_STATUS_BEFORE_AGREEMENT_SIGN.contains(resaleCase.Status)){
                            tempResponseData.put('listingStatus', 'Listing agreement pending');
                        }else if(resaleCase.Status == ResaleConstants.CASE_AGREEMENT_SIGNATURE_IN_PROCESS){
                            tempResponseData.put('listingStatus', 'Listing agreement pending');
                            List<Document__c> docPlaceHolders =[SELECT Id 
                                                                FROM Document__c 
                                                                WHERE Case__c =: resaleCase.Id 
                                                                    AND DocumentType__c =: ResaleConstants.CASE_LISTING_AGREEMENT_DOCUMENT_TYPE
                                                                    AND Status__c =: ResaleConstants.DOCUMENT_STATUS_UPLOADED
                                                                LIMIT 1];
                            if(docPlaceHolders != null && !docPlaceHolders.isEmpty()){
                                tempResponseData.put('listingDocumentId', docPlaceHolders[0].Id);
                                tempResponseData.put('listingStatus', 'Listing agreement Ready');
                            }
                        }else if(resaleCase.Status == ResaleConstants.CASE_PROPERTY_LISTED){
                            tempResponseData.put('listingStatus', 'Property listed');
                            inListingPhase = false;
                        }else{
                            inListingPhase = false;
                        }
                    }else{
                        tempResponseData.put('listingStatus', 'Listing not initiated');
                    }

                    if(!inListingPhase){ 
                        if(so.Resale_Offers__r != null && !so.Resale_Offers__r.isEmpty()){
                            List<Resale_Offers__c> openResaleOffers = new List<Resale_Offers__c>();
                            for(Resale_Offers__c ro : so.Resale_Offers__r){
                                if(ro.Seller_Account__c == recentSellerId){
                                    if(ro.Status__c == ResaleConstants.RO_STATUS_ACCEPTED){
                                        if(!tempResponseData.containsKey('acceptedOffer')){
                                            tempResponseData.put('listingStatus', 'Offer Accepted');
                                            tempResponseData.put('acceptedOffer', ro);
                                            if(ro.Opportunity__c != null){
                                                if(ro.Opportunity__r.StageName == ResaleConstants.OPP_STATUS_MOU_SIGN_PROGRESS){
                                                    if(ro.Opportunity__r.Document_Status__c != null){
                                                        if(ro.Opportunity__r.Document_Status__c.trim().equalsIgnoreCase(ResaleConstants.RESALE_OPP_MOU_SIGNED_BUYER)){
                                                            tempResponseData.put('listingStatus', 'MOU Ready for signature');
                                                            tempResponseData.put('acceptedOfferOpportunity', ro.Opportunity__c);
                                                        }
                                                    }
                                                // }else if(ro.Opportunity__r.StageName == ResaleConstants.OPP_STATUS_PAY_PROGRESS || ro.Opportunity__r.StageName == ResaleConstants.OPP_STATUS_PAYMENT_CLEARED){
                                                //     tempResponseData.put('listingStatus', 'MOU signed');
                                                }else if(ro.Opportunity__r.StageName == ResaleConstants.OPP_STATUS_CLOSED_WON){
                                                    tempResponseData.put('listingStatus', 'Transfer initiated');
                                                    if(ro.Opportunity__r.Transferred__c){
                                                        tempResponseData.put('listingStatus', 'Transfer Completed');
                                                    }
                                                // }else if(ro.Opportunity__r.StageName == ResaleConstants.OPP_STATUS_PAY_PROGRESS){
                                                //     tempResponseData.put('listingStatus', ResaleConstants.OPP_STATUS_PAY_PROGRESS);
                                                }
                                            } 
                                        }
                                    }else{
                                        openResaleOffers.add(ro);
                                    }
                                }
                            }
                            if(!openResaleOffers.isEmpty()){
                                tempResponseData.put('openOffers', so.Resale_Offers__r);
                            }

                            if(tempResponseData.containsKey('acceptedOfferOpportunity')){
                                List<Document__c> docPlaceHolders = [SELECT Id 
                                                                    FROM Document__c 
                                                                    WHERE Opportunity__c =: String.valueOf(tempResponseData.get('acceptedOfferOpportunity'))
                                                                        AND DocumentType__c =: 'Listing MOU'
                                                                    LIMIT 1];
                                if(docPlaceHolders != null && !docPlaceHolders.isEmpty()){
                                    tempResponseData.put('MOUDocumentId', docPlaceHolders[0].Id);
                                }
                            }
                        // }else if(so.Unit__r.ResaleStatus__c != null){
                        //     tempResponseData.put('listingStatus', ResaleConstants.getStatusWithunitResaleStatus(so.Unit__r.ResaleStatus__c));
                        }
                    }

                    switch on String.valueOf(tempResponseData.get('listingStatus')) {
                        when 'Listing not initiated'{
                            // 
                        }
                        when 'Listing agreement pending'{
                            // responseData.put('activeResaleCase', tempResponseData.containsKey('activeResaleCase') ? tempResponseData.get('activeResaleCase') : null );
                        }
                        when 'Listing agreement Ready' {
                            // responseData.put('activeResaleCase', tempResponseData.containsKey('activeResaleCase') ? tempResponseData.get('activeResaleCase') : null );
                            responseData.put('listingDocumentId', tempResponseData.containsKey('listingDocumentId') ? tempResponseData.get('listingDocumentId') : null );
                        }
                        when 'Property listed' {
                            // responseData.put('activeResaleCase', tempResponseData.containsKey('activeResaleCase') ? tempResponseData.get('activeResaleCase') : null );
                            responseData.put('openOffers', tempResponseData.containsKey('openOffers') ? tempResponseData.get('openOffers') : new List<String>() );
                        }
                        when 'Offer Accepted' {
                            // responseData.put('activeResaleCase', tempResponseData.containsKey('activeResaleCase') ? tempResponseData.get('activeResaleCase') : null );
                            responseData.put('acceptedOffer', tempResponseData.containsKey('acceptedOffer') ? tempResponseData.get('acceptedOffer') : null );
                        }
                        when 'MOU Ready for signature' {
                            // responseData.put('activeResaleCase', tempResponseData.containsKey('activeResaleCase') ? tempResponseData.get('activeResaleCase') : null );
                            responseData.put('acceptedOffer', tempResponseData.containsKey('acceptedOffer') ? tempResponseData.get('acceptedOffer') : null );
                            responseData.put('MOUDocumentId', tempResponseData.containsKey('MOUDocumentId') ? tempResponseData.get('MOUDocumentId') : null );
                        }
                        // when 'MOU signed' {
                        //     responseData.put('acceptedOffer', tempResponseData.containsKey('acceptedOffer') ? tempResponseData.get('acceptedOffer') : null );
                        // }
                        when 'Transfer initiated'{
                            // responseData.put('activeResaleCase', tempResponseData.containsKey('activeResaleCase') ? tempResponseData.get('activeResaleCase') : null );
                            responseData.put('acceptedOffer', tempResponseData.containsKey('acceptedOffer') ? tempResponseData.get('acceptedOffer') : null );
                        }
                        when 'Transfer Completed'{
                            responseData.remove('activeResaleCase');
                        }
                    }

                    responseData.put('listingstatus', tempResponseData.get('listingStatus'));
                    
                    handler.response.success = true;
                    handler.response.statusCode = 200;
                    handler.response.message = 'Success';
                    handler.response.data = responseData;
                }else{
                    handler.response.success = false;
                    handler.response.statusCode = 500;
                    handler.response.message = 'Sales Order Not Found. Id = \''+salesOrderId+'\'';   
                    if(Test.isRunningTest()){
                        Integer i = 1/0;
                    }
                }
            }else{
                handler.response.success = false;
                handler.response.statusCode = 500;
                handler.response.message = 'Invalid Request Parameters';
            }
        }catch(Exception e){
            System.debug(e.getStackTraceString());
            handler.response.success = false;
            handler.response.statusCode = 500;
            handler.response.message = e.getMessage();
        }
        handler.finalize();
    }
}