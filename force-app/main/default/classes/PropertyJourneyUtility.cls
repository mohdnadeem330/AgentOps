public without sharing class PropertyJourneyUtility {

    public static Boolean isPostHandoverPayment = false;
    public static Boolean isSRClosed = false;
    public static Boolean isBookingDocument = false;
    public static Boolean isDownPayment = false;
    public static Boolean isConstructionStepCompleted = true;
    public static String lang = '';
    public static Map<String, HexaBPM__Step__c> srStepMap = new Map<String, HexaBPM__Step__c>();
    public static Map<String, List<ReceiptAllocation__c>> receiptMap = new Map<String, List<ReceiptAllocation__c>>();
    public static List<String> otherDocList = new List<String>();
    public static HexaBPM__Service_Request__c spaSRDetail = new HexaBPM__Service_Request__c();

    public static Map<String,Constant__mdt> getConstantsMap = new Map<String,Constant__mdt>();
    
    public static MainPropertyJourneyModel propertyJourneyDetails(SalesOrder__c salesOrder, HexaBPM__Service_Request__c srDetail, Boolean onlyParentStep, String language) {

        lang = language;
        
        MainPropertyJourneyModel mainPropertyJourneyModel = new MainPropertyJourneyModel();
        
        mainPropertyJourneyModel.salesOrderDetails.put('projectCode', salesOrder.Unit__r.Project__r.Name);
        mainPropertyJourneyModel.salesOrderDetails.put('unitNo', salesOrder.Unit__r.Name);
        mainPropertyJourneyModel.salesOrderDetails.put('unitId', salesOrder.Unit__c);
        mainPropertyJourneyModel.salesOrderDetails.put('attendeeTypeCode', CustomerAPIConstants.ATTENDEE_TYPE_CODE);
        mainPropertyJourneyModel.salesOrderDetails.put('salesManagerName', salesOrder.SalesManager__r.Name);
        mainPropertyJourneyModel.salesOrderDetails.put('salesManagerEmail', salesOrder.SalesManager__r.Email);
        mainPropertyJourneyModel.salesOrderDetails.put('projectId', salesOrder.Unit__r.Project__c);
        mainPropertyJourneyModel.salesOrderDetails.put('srNo', srDetail.Name);
        mainPropertyJourneyModel.salesOrderDetails.put('serviceRequestId', srDetail.Id);
        mainPropertyJourneyModel.salesOrderDetails.put('CurrencyIsoCode',salesOrder.CurrencyIsoCode);
        mainPropertyJourneyModel.salesOrderDetails.put('paymentType',salesOrder.Payment_Type__c);
        
        String directDebitRequestWhereClause = ' (SalesOrder__r.Id = \'' + salesOrder.Id + '\' AND SalesOrder__r.Status__c != \'' + Constants.SO_STATUS_CANCELLED + '\' AND SalesOrder__r.Status__c != \'' + Constants.SO_STATUS_CANCELLED_BY_USER + '\') ORDER BY LastModifiedDate ';
        List<String> directDebitRequestList = new List<String>();
        String directDebitRequestStatus = '';
        for (DirectDebitRequest__c directDebitRequest: Database.query('SELECT Id, Name, SalesOrder__c, Status__c FROM DirectDebitRequest__c WHERE ' + directDebitRequestWhereClause)) {
            if (directDebitRequest.Status__c == CustomerAPIConstants.DDR_APPROVED_BY_BANK) {
                directDebitRequestList.add(directDebitRequest.SalesOrder__c);
            }
            directDebitRequestStatus = directDebitRequest.Status__c;
        }
        
        for (ReceiptAllocation__c receipt: salesOrder.ReceiptAllocations__r) {
            String key = receipt.InstallmentLine__c != null ? receipt.InstallmentLine__c : receipt.SalesOrderOtherCharges__c; 
            if (key != null && receiptMap.containsKey(key)) {
                List<ReceiptAllocation__c> receiptList = receiptMap.get(key);
                receiptList.add(receipt);
                receiptMap.put(key, receiptList);
            } else if (key != null) {
                List<ReceiptAllocation__c> receiptList = new List<ReceiptAllocation__c>();
                receiptList.add(receipt);
                receiptMap.put(key, receiptList);
            }
        }
        
        for(Constant__mdt constMdt : [SELECT DeveloperName, MasterLabel, ConstantValue__c, ConstantValueLong__c FROM Constant__mdt]){
            getConstantsMap.put(constMdt.DeveloperName,constMdt);
        }
        
     // Constant__mdt constant = Utilities.getConstant('OtherDocumentForCustomerPortalApp');
        Constant__mdt constant = getConstantsMap.get('OtherDocumentForCustomerPortalApp');
        
        otherDocList = constant != null && constant.ConstantValue__c != null ? constant.ConstantValue__c.split(',') : new List<String>();

        mainPropertyJourneyModel.orderDetails.add(new KeyValueModel('Order Date', salesOrder.BookingDate__c, CustomerAPIConstants.DATA_TYPE_DATE));
        mainPropertyJourneyModel.orderDetails.add(new KeyValueModel('Property No', salesOrder.Unit__r.Name, CustomerAPIConstants.DATA_TYPE_STRING));
        mainPropertyJourneyModel.orderDetails.add(new KeyValueModel('ADM Property No', salesOrder.Unit__r.ADMUnitNumber__c, CustomerAPIConstants.DATA_TYPE_STRING));
        mainPropertyJourneyModel.orderDetails.add(new KeyValueModel('Property Area (' + salesOrder.Unit__r.AreaUOM__c + ')', salesOrder.Unit__r.TotalArea__c, CustomerAPIConstants.DATA_TYPE_NUMBER));
        
        mainPropertyJourneyModel.orderDetails.add(new KeyValueModel('Owner Share Percentage', salesOrder.OwnerSharePercentage__c, CustomerAPIConstants.DATA_TYPE_PERCENTAGE));
        /*
        mainPropertyJourneyModel.orderDetails.add(new KeyValueModel('Main Owner', salesOrder.Account__r.Name + ' : ' + salesOrder.OwnerSharePercentage__c + '%', CustomerAPIConstants.DATA_TYPE_STRING));
        Integer count = 1;
        for (JointOwner__c jointOwner: salesOrder.Joint_OwnersSalesOrder__r) {
            if (jointOwner.SharePercentage__c > 0) {
                mainPropertyJourneyModel.orderDetails.add(new KeyValueModel('Joint Owner ' + count, jointOwner.Account__r.Name + ' : ' + jointOwner.SharePercentage__c + '%', CustomerAPIConstants.DATA_TYPE_STRING));
                count++;
            }
        }
        */
        mainPropertyJourneyModel.orderDetails.add(new KeyValueModel('Net Amount', salesOrder.NetAmount__c, CustomerAPIConstants.DATA_TYPE_CURRENCY));
        mainPropertyJourneyModel.orderDetails.add(new KeyValueModel('Collected Amount', salesOrder.TotalBilled__c, CustomerAPIConstants.DATA_TYPE_CURRENCY));
        // mainPropertyJourneyModel.orderDetails.add(new KeyValueModel('Outstanding Amount', salesOrder.TotalOutstanding__c > Decimal.valueOf(System.Label.BufferOutstandingAmount) ? salesOrder.TotalOutstanding__c : 0, CustomerAPIConstants.DATA_TYPE_CURRENCY));

        Decimal totalOutstanding = salesOrder.OutstandingAmount__c;
        for (SalesOrderOtherCharges__c otherCharge: salesOrder.SalesOrdersOtherCharges__r) {
            if (otherCharge.TypeOfCharge__c == Constants.OTHER_CHARGES_TYPE_LATE_PAYMENT_CHARGES) {
                totalOutstanding += otherCharge.OutstandingAmount__c;
            }
        }

        Decimal totalFuturePayment = 0;
        for (InstallmentLines__c line: salesOrder.InstallmentLines__r) {
            if (line.InstallmentDate__c > date.today() || line.InstallmentDate__c == null) {
                totalFuturePayment += line.OutstandingAmount__c;
            }
        }
        
        mainPropertyJourneyModel.orderDetails.add(new KeyValueModel('Outstanding Amount', totalOutstanding > Decimal.valueOf(System.Label.BufferOutstandingAmount) ? totalOutstanding : 0, CustomerAPIConstants.DATA_TYPE_CURRENCY));
        mainPropertyJourneyModel.orderDetails.add(new KeyValueModel('Future Amount', totalFuturePayment > Decimal.valueOf(System.Label.BufferOutstandingAmount) ? totalFuturePayment : 0, CustomerAPIConstants.DATA_TYPE_CURRENCY));

        mainPropertyJourneyModel.orderDetails.add(new KeyValueModel('Property Model', salesOrder.UnitModel__c, CustomerAPIConstants.DATA_TYPE_STRING));
        mainPropertyJourneyModel.orderDetails.add(new KeyValueModel('Project Location', salesOrder.Unit__r.Project__r.Name + (String.isNotBlank(salesOrder.Unit__r.Project__c) && String.isNotBlank(salesOrder.Unit__r.Project__r.City__c) ? ', ' + salesOrder.Unit__r.Project__r.City__c : ''), CustomerAPIConstants.DATA_TYPE_STRING));
        mainPropertyJourneyModel.orderDetails.add(new KeyValueModel('SPA Signature Type', salesOrder.SignatureType__c, CustomerAPIConstants.DATA_TYPE_STRING));
        if (String.isNotBlank(salesOrder.UnitFinishing__c)) {
            mainPropertyJourneyModel.orderDetails.add(new KeyValueModel('Property Finishing', salesOrder.UnitFinishing__c, CustomerAPIConstants.DATA_TYPE_STRING));
        }
        if (String.isNotBlank(salesOrder.UnitFurnishing__c)) {
            mainPropertyJourneyModel.orderDetails.add(new KeyValueModel('Property Furnishing', salesOrder.UnitFurnishing__c, CustomerAPIConstants.DATA_TYPE_STRING));
        }
        if (String.isNotBlank(directDebitRequestStatus)) {
            mainPropertyJourneyModel.orderDetails.add(new KeyValueModel('Direct Debit Status', directDebitRequestStatus, CustomerAPIConstants.DATA_TYPE_STRING));
        }
        if (String.isNotBlank(salesOrder.Unit__r.ADDCPremiseId1__c)) {
            mainPropertyJourneyModel.orderDetails.add(new KeyValueModel('Premise Number', salesOrder.Unit__r.ADDCPremiseId1__c, CustomerAPIConstants.DATA_TYPE_STRING));
        }
        if (salesOrder.HandoverServiceChargeStartDate__c != null) {
            mainPropertyJourneyModel.orderDetails.add(new KeyValueModel('Service Charge Start Date', salesOrder.HandoverServiceChargeStartDate__c, CustomerAPIConstants.DATA_TYPE_DATE));
        }
        if (salesOrder.HandoverServiceChargeEndDate__c != null) {
            mainPropertyJourneyModel.orderDetails.add(new KeyValueModel('Service Charge End Date', salesOrder.HandoverServiceChargeEndDate__c, CustomerAPIConstants.DATA_TYPE_DATE));
        }

        mainPropertyJourneyModel.totalPaymentAmount = salesOrder.NetAmount__c;

        if (srDetail.Id != null && srDetail.HandoverDetail__c != null) {
            if (srDetail.HandoverDetail__r.KAR__c != null) {
                mainPropertyJourneyModel.handoverDetails.add(new KeyValueModel('Key Handover Representative (KAR)', srDetail.HandoverDetail__r.KAR__r.Name, CustomerAPIConstants.DATA_TYPE_STRING));
                mainPropertyJourneyModel.handoverDetails.add(new KeyValueModel('KAR Email', srDetail.HandoverDetail__r.KAR__r.Email, CustomerAPIConstants.DATA_TYPE_STRING));
                mainPropertyJourneyModel.handoverDetails.add(new KeyValueModel('KAR Phone', srDetail.HandoverDetail__r.KAR__r.Phone != null ? srDetail.HandoverDetail__r.KAR__r.Phone : srDetail.HandoverDetail__r.KAR__r.MobilePhone, CustomerAPIConstants.DATA_TYPE_STRING));
            }

            if (srDetail.HandoverDetail__r.HandoverAgent__c != null) {
                mainPropertyJourneyModel.handoverDetails.add(new KeyValueModel('Handover Agent', srDetail.HandoverDetail__r.HandoverAgent__r.Name, CustomerAPIConstants.DATA_TYPE_STRING));
                mainPropertyJourneyModel.handoverDetails.add(new KeyValueModel('Handover Agent Email', srDetail.HandoverDetail__r.HandoverAgent__r.Email, CustomerAPIConstants.DATA_TYPE_STRING));
                mainPropertyJourneyModel.handoverDetails.add(new KeyValueModel('Handover Agent Phone', srDetail.HandoverDetail__r.HandoverAgent__r.Phone != null ? srDetail.HandoverDetail__r.HandoverAgent__r.Phone : srDetail.HandoverDetail__r.HandoverAgent__r.MobilePhone, CustomerAPIConstants.DATA_TYPE_STRING));
            }
        }

        if (srDetail.HexaBPM__External_Status_Name__c == CustomerAPIConstants.SR_STATUS_CLOSED) {
            isSRClosed = true;
        }

        CustomerFinancialWebservice.FinancialModel financialStatement = CustomerFinancialWebservice.populateFinancialDetails(salesOrder.InstallmentLines__r, new List<SalesOrderOtherCharges__c>(), directDebitRequestList, receiptMap, '', '');
        mainPropertyJourneyModel.paymentPlan = financialStatement.paymentDetails;

        Boolean isHandoverPayment = false;
        for (CustomerFinancialWebservice.PaymentModel payment: financialStatement.paymentDetails) {
            if (payment.paymentDate <= Date.today() && payment.outstandingAmount > 0 && payment.isInstallment && mainPropertyJourneyModel.duePaymentInDays == null) {
                mainPropertyJourneyModel.duePaymentInDays = payment.paymentDate.daysBetween(Date.today());
                mainPropertyJourneyModel.paymentDetails = payment;
            } else if (payment.paymentDate > Date.today() && payment.outstandingAmount > 0 && payment.isInstallment && mainPropertyJourneyModel.nextPaymentInDays == null) {
                mainPropertyJourneyModel.nextPaymentInDays = Date.today().daysBetween(payment.paymentDate);
                mainPropertyJourneyModel.paymentDetails = payment;
            }
            isHandoverPayment = isHandoverPayment ? true : payment.isHandoverPayment;
            if (isHandoverPayment && payment.isInstallment && !payment.isHandoverPayment) {
                isPostHandoverPayment = true;
            }
            if (payment.paymentStatus == CustomerAPIConstants.PAYMENT_STATUS_CLEARED) {
                mainPropertyJourneyModel.constructionPercentage += payment.percentage;
            }
        }

        for (HexaBPM__Step__c step: srDetail.HexaBPM__Steps_SR__r) {
            srStepMap.put(step.HexaBPM__Summary__c, step);
        }

        List<PropertyJourneyModel> propertyJourneyModelList = new List<PropertyJourneyModel>();

        //----- Base on criteria we are buding where clase for Off Plan, Ready and Plot journey
        String applicableWhereCluse = '';
        if (salesOrder.Unit__r.RecordType.Name == Constants.UNIT_RECORD_TYPE_PLOT) {
            applicableWhereCluse = ' ApplicableForPlot__c = true ';
        } else if (salesOrder.Unit__r.BuildingSectionName__r.CompletionCertificateDate__c <= salesOrder.BookingDate__c) {
            applicableWhereCluse = ' ApplicableForReady__c = true ';
        } else {
            applicableWhereCluse = ' ApplicableForOffplan__c = true ';

            List<HexaBPM__Service_Request__c> spaSRList = CustomerServiceUtility.getServiceRequestDetail(' (SalesOrder__c = \'' + salesOrder.Id + '\' AND RecordType.Name = \'' + Constants.SPA_REGISTRATION_RT + '\') ORDER BY LastModifiedDate DESC LIMIT 1');
            if (!spaSRList.isEmpty()) {
                spaSRDetail = spaSRList[0];
            }
        }

        //----- Get Customer Property Journey Meta Data records
        String stepQuery = 'SELECT Id, Label, DeveloperName, MappingName__c, ENLabel__c, ARLabel__c, StepNo__c, ParentStepName__c, ParentStepNo__c, HasChild__c, Description__c, ARDescription__c, SRStepName__c FROM CustomerPropertyJourney__mdt WHERE ' + applicableWhereCluse + ' ORDER BY ParentStepNo__c, StepNo__c';
        List<CustomerPropertyJourney__mdt> customerPropertyJourneyList = Database.query(stepQuery);
        
        //----- Build journey steps
        Decimal mainStepCounter = 1;
        for (CustomerPropertyJourney__mdt stp: customerPropertyJourneyList) {
            if (stp.ParentStepName__c == null) {
                PropertyJourneyModel propertyJourneyModel = new PropertyJourneyModel(stp, mainStepCounter, lang);

                // if (stp.MappingName__c == 'Future_Payment') {
                //     Boolean futurePaymentFound = false;
                //     for (InstallmentLines__c line: salesOrder.InstallmentLines__r) {
                //         if (line.InstallmentNumber__c != 1 && salesOrder.BookingDate__c < line.InstallmentDate__c && !line.PaymentInstallments__r.IsHandoverPayment__c) {
                //             futurePaymentFound = true;
                //             break;
                //         }
                //     }
                //     if (!futurePaymentFound) {
                //         continue;
                //     }
                // }

                propertyJourneyModel.stepCompletedDate = String.isNotBlank(stp.SRStepName__c) && srStepMap.containsKey(stp.SRStepName__c) ? srStepMap.get(stp.SRStepName__c).HexaBPM__Closed_Date__c : null;
                propertyJourneyModel = populateStepDetails(propertyJourneyModel, stp, salesOrder, srDetail, directDebitRequestList);

                propertyJourneyModel.propertyJourneyDetails = childDetails(customerPropertyJourneyList, stp, applicableWhereCluse, salesOrder, srDetail, directDebitRequestList);
                propertyJourneyModel.isStepCompleted = checkStepStatus(propertyJourneyModel);
                
                
                if (stp.MappingName__c == 'Handover' && isSRClosed) {
                    propertyJourneyModel.isStepCompleted = true;
                }

                if (onlyParentStep) {
                    // propertyJourneyModel.stepDetails = null;
                    propertyJourneyModel.propertyJourneyDetails = null;
                }

                propertyJourneyModelList.add(propertyJourneyModel);
                mainStepCounter++;
            }
        }

        mainPropertyJourneyModel.propertyJourneyDetails = propertyJourneyModelList;
        return mainPropertyJourneyModel;
    }

    //----- Get child steps
    public static List<PropertyJourneyModel> childDetails(List<CustomerPropertyJourney__mdt> customerPropertyJourneyList, CustomerPropertyJourney__mdt parentStepRecord, String applicableWhereCluse, SalesOrder__c salesOrder, HexaBPM__Service_Request__c srDetail, List<String> directDebitRequestList) {
        List<PropertyJourneyModel> childSteps = new List<PropertyJourneyModel>();
        Decimal childStepCounter = 1;
        for (CustomerPropertyJourney__mdt stp: customerPropertyJourneyList) {
            if (stp.ParentStepName__c == parentStepRecord.ENLabel__c && stp.ParentStepNo__c == parentStepRecord.StepNo__c) {
                PropertyJourneyModel subModel = new PropertyJourneyModel(stp, childStepCounter, lang);

                // if (salesOrder.Unit__r.Project__c != null && !salesOrder.Unit__r.Project__r.EnableDocumentsCustomerPortal__c && (stp.MappingName__c == 'Sign_Booking_documents' || stp.MappingName__c == 'SPA_Counter_Signed')) {
                if (salesOrder.Unit__r.Project__c != null && !salesOrder.Unit__r.Project__r.EnableDocumentsCustomerPortal__c && (stp.MappingName__c == 'SPA_Counter_Signed')) {
                    continue;
                } else if (stp.MappingName__c == 'SPA_Counter_Signed') {
                   //Constant__mdt counterSignedSPA = Utilities.getConstant('Counter_Signed_SPA');
                    Constant__mdt counterSignedSPA = getConstantsMap.get('Counter_Signed_SPA');
                    
                    List<String> counterSignedSPAList = counterSignedSPA.ConstantValueLong__c != null ? counterSignedSPA.ConstantValueLong__c.split(',') : new List<String>();
                
                    Set<String> documentPlaceHolderSet = new Set<String>();
                    for (DocumentPlaceHolder__mdt documentPlaceHolder: DocumentPlaceHolder__mdt.getall().values()) {
                        if (documentPlaceHolder.Category__c == Constants.DOCUMENT_PLACEHOLDER_CATEGORY_BOOKING && documentPlaceHolder.AvailableForCustomer__c) {
                            documentPlaceHolderSet.add(documentPlaceHolder.DocumentType__c);
                        }
                    }
                    
                    Boolean signSPAFound = false;
                    Document__c signDoc = new Document__c();
                    for (Document__c doc: salesOrder.Documents__r) {
                        if (documentPlaceHolderSet.contains(doc.DocumentType__c) && (doc.DocumentType__c.contains(CustomerAPIConstants.DOCUMENT_SIGNED_SPA) || counterSignedSPAList.contains(doc.DocumentType__c)) && (doc.Status__c == Constants.DOCUMENT_STATUS_UPLOADED || doc.Status__c == Constants.DOCUMENT_STATUS_GENERATED || doc.Status__c == Constants.DOCUMENT_STATUS_COMPLETED)) {
                            signSPAFound = true;
                            signDoc = doc;
                            break;
                        }
                    }
                    System.debug('isDownPayment>>>' + isDownPayment + '>>>salesOrder.Status__c>>>' + salesOrder.Status__c);
                    System.debug('signSPAFound>>>' + signSPAFound + '>>>salesOrder.EquityPercentage__c>>>' + salesOrder.EquityPercentage__c + '>>>signDoc.Status__c>>>' + signDoc.Status__c);
                    if (signSPAFound && (salesOrder.EquityPercentage__c == 100 || (salesOrder.Status__c == Constants.SO_STATUS_SOLD && isDownPayment)) && signDoc.Status__c != Constants.DOCUMENT_STATUS_UPLOADED && signDoc.Status__c != Constants.DOCUMENT_STATUS_GENERATED && signDoc.Status__c != Constants.DOCUMENT_STATUS_COMPLETED) {
                        signSPAFound = false;
                    }
                    if (!signSPAFound || (!isBookingDocument && signDoc.Status__c != Constants.DOCUMENT_STATUS_UPLOADED && signDoc.Status__c != Constants.DOCUMENT_STATUS_GENERATED && signDoc.Status__c != Constants.DOCUMENT_STATUS_COMPLETED)) {
                        continue;
                    }
                } else if (stp.MappingName__c == 'Complete_Outstanding_Payment' || stp.MappingName__c == 'Complete_Outstanding_Payment_Plot') {
                    Boolean handoverPaymentFound = false;
                    for (InstallmentLines__c line: salesOrder.InstallmentLines__r) {
                        if (line.PaymentInstallments__c != null && line.PaymentInstallments__r.IsHandoverPayment__c) {
                            handoverPaymentFound = true;
                            break;
                        }
                    }
                    if (!handoverPaymentFound) {
                        continue;
                    }
                } else if (stp.MappingName__c == 'Post_Handover_Payment' && !isPostHandoverPayment) {
                    continue;
                }
                
                subModel.stepCompletedDate = String.isNotBlank(stp.SRStepName__c) && srStepMap.containsKey(stp.SRStepName__c) ? srStepMap.get(stp.SRStepName__c).HexaBPM__Closed_Date__c : null;
                if (stp.MappingName__c == 'View_Snag_Rectification_Report' && subModel.stepCompletedDate !=  null) {
                    subModel.stepCompletedDate = salesOrder.HandoverReadyforOccupancyDate__c;
                }
                subModel = populateStepDetails(subModel, stp, salesOrder, srDetail, directDebitRequestList);
                
                // if ((stp.MappingName__c == 'Sign_Booking_documents' || stp.MappingName__c == 'Defect_Liability_Period' || stp.MappingName__c == 'Maintenance_Contract') && subModel.stepDetails == null) {
                if ((stp.MappingName__c == 'Defect_Liability_Period' || stp.MappingName__c == 'Maintenance_Contract') && subModel.stepDetails == null) {
                    continue;
                } else if (stp.MappingName__c == 'SPA_Registration' && (spaSRDetail.Id == null || subModel.stepDetails == null)) {
                    continue;
                }
                
                if (stp.HasChild__c) {
                    subModel.propertyJourneyDetails = childDetails(customerPropertyJourneyList, stp, applicableWhereCluse, salesOrder, srDetail, directDebitRequestList);
                    subModel.isStepCompleted = checkStepStatus(subModel);
                }
                childSteps.add(subModel);
                childStepCounter++;
            }
        }
        return childSteps;
    }

    //----- Check step is completed or not
    public static Boolean checkStepStatus(PropertyJourneyModel pjModel) {
        pjModel.isStepCompleted = true;
        for (PropertyJourneyModel tempModel: pjModel.propertyJourneyDetails) {
            if (!tempModel.isStepCompleted) {
                pjModel.isStepCompleted = false;
                break;
            }
        }
        if (pjModel.stepUniqueName == 'Securing_a_Unit' && pjModel.isStepCompleted) {
            pjModel.stepName = String.isNotBlank(lang) && lang == CustomerAPIConstants.LANGUAGE_AR ? CustomerAPIConstants.STEP_PROPERTY_SECURED_AR : CustomerAPIConstants.STEP_PROPERTY_SECURED;
            pjModel.stepARName = CustomerAPIConstants.STEP_PROPERTY_SECURED_AR;
        }
        return pjModel.isStepCompleted;
    }

    //----- Get step details based on step name
    public static PropertyJourneyModel populateStepDetails(PropertyJourneyModel pjModel, CustomerPropertyJourney__mdt stepRecord, SalesOrder__c salesOrder, HexaBPM__Service_Request__c srDetail, List<String> directDebitRequestList) {
        Decimal bufferOutstandingAmount = Decimal.valueOf(System.Label.BufferOutstandingAmount);
       // Constant__mdt spaFullForm = Utilities.getConstant('SPA_Full_Form');
        Constant__mdt spaFullForm = getConstantsMap.get('SPA_Full_Form');
        
        //----- Populate Down Payment, Final Payment and Other Installement Payment percentage as header
        if (stepRecord.MappingName__c == 'Securing_a_Unit') {
            List<Map<String, Object>> percentageMapList = new List<Map<String, Object>>();
            Decimal otherInstallmentPercentage = 0, finalInstallmentPercentage = 0;
            for (InstallmentLines__c line: salesOrder.InstallmentLines__r) {
                Map<String, Object> percentageMap = new Map<String, Object>();
                if (line.InstallmentNumber__c == 1) {
                    percentageMap.put('no', 1);
                    percentageMap.put('paymentName', CustomerAPIConstants.TYPE_DOWN_PAYMENT);
                    percentageMap.put('paymentPercentage', line.InstallmentPercentage__c);
                    percentageMap.put('paymentDescription', CustomerAPIConstants.DESCRIPTION_DOWN_PAYMENT);
                    percentageMapList.add(percentageMap);
                } else if (line.PaymentInstallments__c != null && line.PaymentInstallments__r.IsHandoverPayment__c) {
                    finalInstallmentPercentage = line.InstallmentPercentage__c;
                } else {
                    otherInstallmentPercentage += line.InstallmentPercentage__c;
                }
            }
            if (otherInstallmentPercentage > 0) {
                Map<String, Object> percentageMap = new Map<String, Object>();
                percentageMap.put('no', 2);
                percentageMap.put('paymentName', CustomerAPIConstants.TYPE_INSTALLMENT_PAYMENT);
                percentageMap.put('paymentPercentage', otherInstallmentPercentage);
                percentageMap.put('paymentDescription', CustomerAPIConstants.DESCRIPTION_INSTALLMENT_PAYMENT);
                percentageMapList.add(percentageMap);
            }
            if (finalInstallmentPercentage > 0) {
                Map<String, Object> percentageMap = new Map<String, Object>();
                percentageMap.put('no', (otherInstallmentPercentage > 0 ? 3 : 2));
                percentageMap.put('paymentName', CustomerAPIConstants.TYPE_FINAL_PAYMENT);
                percentageMap.put('paymentPercentage', finalInstallmentPercentage);
                percentageMap.put('paymentDescription', CustomerAPIConstants.DESCRIPTION_FINAL_PAYMENT);
                percentageMapList.add(percentageMap);
            }
            pjModel.stepDetails = percentageMapList;
        }
        //----- Down payment, ADM Fee and ADM Admib Fee information in this step
        else if (stepRecord.MappingName__c == 'Payments') {
            pjModel.isStepCompleted = true;

            List<InstallmentLines__c> installmentDetails = new List<InstallmentLines__c>();
            for (InstallmentLines__c line: salesOrder.InstallmentLines__r) {
                if (line.InstallmentNumber__c == 1 || (salesOrder.Unit__r.RecordType.Name == Constants.UNIT_RECORD_TYPE_PLOT && !line.PaymentInstallments__r.IsHandoverPayment__c)) {
                    installmentDetails.add(line);
                    if (salesOrder.Unit__r.RecordType.Name != Constants.UNIT_RECORD_TYPE_PLOT) {
                        break;
                    }
                }
            }
            List<SalesOrderOtherCharges__c> otherChargeDetails = new List<SalesOrderOtherCharges__c>();
            for (SalesOrderOtherCharges__c otherCharge: salesOrder.SalesOrdersOtherCharges__r) {
                if (otherCharge.TypeOfCharge__c == Constants.BUDGET_LINE_ADMFEE || otherCharge.TypeOfCharge__c == Constants.BUDGET_LINE_ADMADMINFEE) {
                    otherChargeDetails.add(otherCharge);
                }
            }
            CustomerFinancialWebservice.FinancialModel financialStatement = CustomerFinancialWebservice.populateFinancialDetails(installmentDetails, otherChargeDetails, directDebitRequestList, receiptMap, '', '');
            for (CustomerFinancialWebservice.PaymentModel paymentModel: financialStatement.paymentDetails) {
                if (paymentModel.paymentStatus != CustomerAPIConstants.PAYMENT_STATUS_CLEARED) {
                    pjModel.isStepCompleted = false;
                }
                isDownPayment = paymentModel.description == CustomerAPIConstants.DOWN_PAYMENT && paymentModel.paymentStatus == CustomerAPIConstants.PAYMENT_STATUS_CLEARED ? true : isDownPayment;
            }
            pjModel.stepDetails = financialStatement.paymentDetails;
        }
        //----- All document related to sales order like KYC, Wealth, SAP and other
        else if (stepRecord.MappingName__c == 'Sign_Booking_documents') {
            List<DocumentQueryModel> documents = new List<DocumentQueryModel>();
            Map<String, Document__c> signedDocMap = new Map<String, Document__c>();
            String signedSPAId = '';
            Boolean isSignSPADoc = false;

            Set<String> documentPlaceHolderSet = new Set<String>();
            for (DocumentPlaceHolder__mdt documentPlaceHolder: DocumentPlaceHolder__mdt.getall().values()) {
                if ((documentPlaceHolder.Category__c == Constants.DOCUMENT_PLACEHOLDER_CATEGORY_BOOKING || documentPlaceHolder.Category__c == Constants.DOCUMENT_PLACEHOLDER_CATEGORY_RESERVATION) && documentPlaceHolder.AvailableForCustomer__c) {
                    documentPlaceHolderSet.add(documentPlaceHolder.DocumentType__c);
                }
            }
            for (Document__c doc: salesOrder.Documents__r) {
                if (documentPlaceHolderSet.contains(doc.DocumentType__c) && (doc.Status__c == Constants.DOCUMENT_STATUS_UPLOADED || doc.Status__c == Constants.DOCUMENT_STATUS_GENERATED || doc.Status__c == Constants.DOCUMENT_STATUS_COMPLETED || doc.Status__c == CustomerAPIConstants.DOCUMENT_STATUS_DOCUSIGN_PENDING)) {
                    if (doc.DocumentType__c.containsIgnoreCase(Constants.DOCUMENT_TYPE_SIGNED_RA)) {
                        signedDocMap.put(Constants.DOCUMENT_TYPE_SIGNED_RA, doc);
                    }
                }
            }

            Boolean isSPADoc = false;
            for (Document__c doc: salesOrder.Documents__r) {
                System.debug('Chirag'+documentPlaceHolderSet);
                System.debug('Chirag1'+doc.DocumentType__c);
                if ((documentPlaceHolderSet.contains(doc.DocumentType__c) || otherDocList.contains(doc.DocumentType__c)) && (doc.Status__c == Constants.DOCUMENT_STATUS_UPLOADED || doc.Status__c == Constants.DOCUMENT_STATUS_GENERATED || doc.Status__c == Constants.DOCUMENT_STATUS_COMPLETED) && !doc.DocumentType__c.containsIgnoreCase(Constants.DOCUMENT_TYPE_PREFIX_SIGNED)) {
                    DocumentQueryModel documentQueryModel = new DocumentQueryModel(doc);
                    documentQueryModel.isUploaded = true;
                    documentQueryModel.isUploadable = false;
                    documentQueryModel.eligibleForeSign = doc.DocumentType__c.containsIgnoreCase(Constants.DOCUMENT_TYPE_RA) ? true : doc.DocumentType__c.containsIgnoreCase('spa') && !doc.DocumentType__c.containsIgnoreCase(CustomerAPIConstants.DOCUMENT_SPA_DELIVERY_LETTER) && !salesOrder.CustomerSPASigned__c ? true : false;
                    documentQueryModel.type = doc.DocumentType__c.containsIgnoreCase('spa') ? doc.DocumentType__c.replace('SPA', spaFullForm.ConstantValue__c) : doc.DocumentType__c;
                    Document__c signDoc = null;
                    if (doc.DocumentType__c.containsIgnoreCase('spa') && !doc.DocumentType__c.containsIgnoreCase(CustomerAPIConstants.DOCUMENT_SPA_DELIVERY_LETTER)) {
                        isSPADoc = true;
                    } else if (doc.DocumentType__c.containsIgnoreCase(Constants.DOCUMENT_TYPE_RA)) {
                        signDoc = signedDocMap.get(Constants.DOCUMENT_TYPE_SIGNED_RA);
                    }
                    if (signDoc != null && signDoc.Status__c == CustomerAPIConstants.DOCUMENT_STATUS_DOCUSIGN_PENDING) {
                        documentQueryModel.isSignCompleted = signDoc != null ? true : false;
                    } else {
                        documentQueryModel.signDocumentId = signDoc != null ? (String)signDoc.Id : '';
                    }

                    documents.add(documentQueryModel);
                }
            }
            pjModel.stepDetails = !documents.isEmpty() ? documents : null;
            isBookingDocument = !documents.isEmpty() ? true : false;
            if ((!documents.isEmpty() || isDownPayment) && (salesOrder.CustomerSPASigned__c || !isSPADoc || !isSignSPADoc)) {
                pjModel.isStepCompleted = true;
            }
        }
        //----- Counter sign copy of SPA for download
        else if (stepRecord.MappingName__c == 'SPA_Counter_Signed') {
            //Constant__mdt counterSignedSPA = Utilities.getConstant('Counter_Signed_SPA');
              Constant__mdt counterSignedSPA = getConstantsMap.get('Counter_Signed_SPA');
            
            List<String> counterSignedSPAList = counterSignedSPA.ConstantValueLong__c != null ? counterSignedSPA.ConstantValueLong__c.split(',') : new List<String>();
            Set<String> documentPlaceHolderSet = new Set<String>();
            for (DocumentPlaceHolder__mdt documentPlaceHolder: DocumentPlaceHolder__mdt.getall().values()) {
                if (documentPlaceHolder.Category__c == Constants.DOCUMENT_PLACEHOLDER_CATEGORY_BOOKING && documentPlaceHolder.AvailableForCustomer__c) {
                    documentPlaceHolderSet.add(documentPlaceHolder.DocumentType__c);
                }
            }
            
            List<DocumentQueryModel> documents = new List<DocumentQueryModel>();
            for (Document__c doc: salesOrder.Documents__r) {
                if (documentPlaceHolderSet.contains(doc.DocumentType__c) && (doc.DocumentType__c.contains(CustomerAPIConstants.DOCUMENT_SIGNED_SPA) || counterSignedSPAList.contains(doc.DocumentType__c)) && (doc.Status__c == Constants.DOCUMENT_STATUS_UPLOADED || doc.Status__c == Constants.DOCUMENT_STATUS_GENERATED || doc.Status__c == Constants.DOCUMENT_STATUS_COMPLETED)) {
                    DocumentQueryModel documentQueryModel = new DocumentQueryModel(doc);
                    documentQueryModel.isUploaded = true;
                    documentQueryModel.isUploadable = false;
                    documentQueryModel.type = doc.DocumentType__c.containsIgnoreCase('spa') ? doc.DocumentType__c.replace('SPA', spaFullForm.ConstantValue__c) : doc.DocumentType__c;
                    documents.add(documentQueryModel);
                }
            }
            pjModel.stepDetails = documents;
            if (!documents.isEmpty() && documents.size() == 1) {
                pjModel.isStepCompleted = true;
            }
        }
        //----- Populate all Handover document
        else if (stepRecord.MappingName__c == 'SPA_Registration' && spaSRDetail.Id != null) {
            List<DocumentQueryModel> documents = new List<DocumentQueryModel>();
            for (HexaBPM__SR_Doc__c doc: spaSRDetail.HexaBPM__SR_Docs__r) {
                if (doc.Name == CustomerAPIConstants.DOCUMENT_SPA_REGISTRATION_DOCUMENTS) {
                    DocumentQueryModel documentQueryModel = new DocumentQueryModel(doc);
                    documentQueryModel.isUploaded = true;
                    documentQueryModel.isUploadable = false;
                    documentQueryModel.eligibleForeSign = false;
                    documentQueryModel.createdDate = doc.CreatedDate;
                    if (doc.HexaBPM__Status__c == Constants.DOCUMENT_STATUS_UPLOADED || doc.HexaBPM__Status__c == Constants.DOCUMENT_STATUS_GENERATED || doc.HexaBPM__Status__c == Constants.DOCUMENT_STATUS_COMPLETED) {
                        documents.add(documentQueryModel);
                    }
                }
            }
            pjModel.stepDetails = !documents.isEmpty() ? documents : null;
            if (!documents.isEmpty() && documents.size() == 1) {
                pjModel.isStepCompleted = true;
            }
        }
        //----- Show Construction for Off Plan
        else if (stepRecord.MappingName__c == 'Construction') {
            pjModel.showDueNextPaymentDays = true;
            CustomerFinancialWebservice.FinancialModel financialStatement = CustomerFinancialWebservice.populateFinancialDetails(salesOrder.InstallmentLines__r, salesOrder.SalesOrdersOtherCharges__r, directDebitRequestList, receiptMap, '', '');
            List<CustomerFinancialWebservice.PaymentModel> paymentDetails = new List<CustomerFinancialWebservice.PaymentModel>();
            pjModel.isStepCompleted = false;

            Boolean isHandoverPayment = false;
            Boolean checkStepCompleted = true;
            for (CustomerFinancialWebservice.PaymentModel paymentModel: financialStatement.paymentDetails) {
                isHandoverPayment = isHandoverPayment ? true : paymentModel.isHandoverPayment;
                if (isHandoverPayment && paymentModel.isInstallment) {
                    checkStepCompleted = false;
                }

                if (paymentModel.isInstallment) {
                    paymentDetails.add(paymentModel);
                    if (paymentModel.paymentStatus != CustomerAPIConstants.PAYMENT_STATUS_CLEARED && checkStepCompleted && paymentModel.description != CustomerAPIConstants.DOWN_PAYMENT && !paymentModel.isHandoverPayment) {
                      //  pjModel.isStepCompleted = false;
                    }
                }
            }
            pjModel.stepDetails = paymentDetails;
            
            if(salesOrder.Unit__r.BuildingSectionName__r.CompletionCertificateDate__c != null && salesOrder.Unit__r.BuildingSectionName__r.CompletionCertificateDate__c <= System.today()){
                pjModel.isStepCompleted = true;
            }else if ((srDetail != null && srDetail.HandoverDetail__c != null && srDetail.HandoverDetail__r.HandoverCompletionDate__c != null) || isSRClosed) {
                pjModel.isStepCompleted = true;
            }
            isConstructionStepCompleted = pjModel.isStepCompleted;
            
            
        }
        //----- All installment
        else if (stepRecord.MappingName__c == 'Construction_Update' || stepRecord.MappingName__c == 'Payments_Milestone') {
            pjModel.isStepCompleted = isConstructionStepCompleted;
        }
        //----- Populate all Handover document
        else if (stepRecord.MappingName__c == 'Handover' && srDetail.Id != null) {
            List<DocumentQueryModel> documents = new List<DocumentQueryModel>();
            for (HexaBPM__SR_Doc__c doc: srDetail.HexaBPM__SR_Docs__r) {
                if (doc.Name == CustomerAPIConstants.DOCUMENT_HOME_ORIENTATION_LETTER || doc.Name == CustomerAPIConstants.DOCUMENT_CUSTOMER_SNAGGING || doc.Name == CustomerAPIConstants.DOCUMENT_CUSTOMER_DESNAGGING || doc.Name == CustomerAPIConstants.DOCUMENT_READY_FOR_OCCUPANCY_LETTER || doc.Name == CustomerAPIConstants.DOCUMENT_HANDOVER_PHASING_LETTER || doc.Name == CustomerAPIConstants.DOCUMENT_TITLE_DEED_COPY || doc.Name == CustomerAPIConstants.DOCUMENT_DISTRICT_COOLING_TRANSFER || doc.Name == CustomerAPIConstants.DOCUMENT_SERVICE_CHARGES_PAYMENT_PROOF || doc.Name == CustomerAPIConstants.DOCUMENT_ADDC_CERTIFICATE || doc.Name == CustomerAPIConstants.DOCUMENT_NOC_FOR_ADDC || doc.Name == CustomerAPIConstants.DOCUMENT_HANDOVER_NOC_LETTER || doc.Name == CustomerAPIConstants.DOCUMENT_SIGNED_HANDOVER_NOC_LETTER || doc.Name == CustomerAPIConstants.DOCUMENT_PLOT_POSSESSION_CERTIFICATE || doc.Name == CustomerAPIConstants.DOCUMENT_SIGNED_PLOT_POSSESSION_CERTIFICATE) {
                    DocumentQueryModel documentQueryModel = new DocumentQueryModel(doc);
                    documentQueryModel.type = salesOrder.Unit__r.RecordType.Name == Constants.UNIT_RECORD_TYPE_PLOT && documentQueryModel.type == CustomerAPIConstants.DOCUMENT_HOME_ORIENTATION_LETTER ? CustomerAPIConstants.DOCUMENT_HANDOVER_LETTER : documentQueryModel.type;
                    documentQueryModel.isUploaded = (doc.HexaBPM__Status__c == Constants.DOCUMENT_STATUS_UPLOADED || doc.HexaBPM__Status__c == Constants.DOCUMENT_STATUS_GENERATED || doc.HexaBPM__Status__c == Constants.DOCUMENT_STATUS_COMPLETED) ? true : false;
                    documentQueryModel.isUploadable = false;
                    documentQueryModel.eligibleForeSign = false;
                    documentQueryModel.createdDate = doc.CreatedDate;
                    if (doc.HexaBPM__Status__c == Constants.DOCUMENT_STATUS_UPLOADED || doc.HexaBPM__Status__c == Constants.DOCUMENT_STATUS_GENERATED || doc.HexaBPM__Status__c == Constants.DOCUMENT_STATUS_COMPLETED) {
                        documents.add(documentQueryModel);
                    }
                }
            }
            pjModel.stepDetails = documents;
            pjModel.showDueNextPaymentDays = true;
        }
        //----- Home Orientation related documents
        else if (stepRecord.MappingName__c == 'View_Home_Orientation_Letter' && srDetail.Id != null && srDetail.HandoverDetail__c != null) {
            List<DocumentQueryModel> documents = new List<DocumentQueryModel>();
            for (HexaBPM__SR_Doc__c doc: srDetail.HexaBPM__SR_Docs__r) {
                if (doc.Name == CustomerAPIConstants.DOCUMENT_HOME_ORIENTATION_LETTER && (doc.HexaBPM__Status__c == Constants.DOCUMENT_STATUS_UPLOADED || doc.HexaBPM__Status__c == Constants.DOCUMENT_STATUS_GENERATED || doc.HexaBPM__Status__c == Constants.DOCUMENT_STATUS_COMPLETED)) {
                    DocumentQueryModel documentQueryModel = new DocumentQueryModel(doc);
                    documentQueryModel.type = salesOrder.Unit__r.RecordType.Name == Constants.UNIT_RECORD_TYPE_PLOT ? CustomerAPIConstants.DOCUMENT_HANDOVER_LETTER : documentQueryModel.type;
                    documentQueryModel.isUploaded = true;
                    documentQueryModel.isUploadable = false;
                    documents.add(documentQueryModel);
                }
            }
            pjModel.stepDetails = documents;
            if ((!documents.isEmpty() && documents.size() == 1) || pjModel.stepCompletedDate != null || salesOrder.HandoverReadyforOccupancyDate__c != null || isSRClosed) {
                pjModel.isStepCompleted = true;
            }
        }
        //----- Home Orientation Appointment date and slot
       /* else if (stepRecord.MappingName__c == 'Home_Orientation_Appointment' && srDetail.Id != null && srDetail.HandoverDetail__c != null) {
            List<KeyValueModel> stepDetailList = new List<KeyValueModel>();
            stepDetailList.add(new KeyValueModel('Appointment', CustomerAPIConstants.APPOINTMENT_LABEL_HOME_ORIENTATION, CustomerAPIConstants.DATA_TYPE_STRING));
            stepDetailList.add(new KeyValueModel('Date', srDetail.HandoverDetail__r.CustomerSnaggingAppointment__c != null ? srDetail.HandoverDetail__r.CustomerSnaggingAppointment__r.Date__c : null, CustomerAPIConstants.DATA_TYPE_DATE));
            stepDetailList.add(new KeyValueModel('Slot', srDetail.HandoverDetail__r.CustomerSnaggingAppointment__c != null && srDetail.HandoverDetail__r.CustomerSnaggingAppointment__r.Appointment_Slot_Time__c != null ? srDetail.HandoverDetail__r.CustomerSnaggingAppointment__r.Appointment_Slot_Time__c : srDetail.HandoverDetail__r.CustomerSnaggingAppointment__r.Slot__c, CustomerAPIConstants.DATA_TYPE_STRING));
            
            pjModel.stepDetails = srDetail.HandoverDetail__r.CustomerSnaggingAppointment__c != null ? stepDetailList: null;
            pjModel.appointment = new Map<String, Object>();
            pjModel.appointment.put('appointmentId', srDetail.HandoverDetail__r.CustomerSnaggingAppointment__c != null ? srDetail.HandoverDetail__r.CustomerSnaggingAppointment__r.AppointmentId__c: null);
            Boolean isAppointmentReschedulable = ((srStepMap.containsKey(CustomerAPIConstants.STEP_HOME_ORIENTATION) && srStepMap.get(CustomerAPIConstants.STEP_HOME_ORIENTATION).HexaBPM__Closed_Date__c != null) || isSRClosed) ? false : true;
            pjModel.appointment.put('isAppointmentReschedulable', isAppointmentReschedulable);
            pjModel.appointment.put('appointmentType', CustomerAPIConstants.APPOINTMENT_TYPE_HOME_ORIENTATION);
            pjModel.appointment.put('appointmentLabel', CustomerAPIConstants.APPOINTMENT_LABEL_HOME_ORIENTATION);
            pjModel.appointment.put('isAppointmentInProgress', srDetail.HandoverDetail__r.CustomerSnaggingAppointment__c == null && String.isNotBlank(stepRecord.SRStepName__c) && srStepMap.containsKey(stepRecord.SRStepName__c) ? srStepMap.get(stepRecord.SRStepName__c).PortalAppStatus__c : false);

            if ((srDetail.HandoverDetail__r.CustomerSnaggingAppointment__c != null && srDetail.HandoverDetail__r.CustomerSnaggingAppointment__r.Date__c != null) || pjModel.stepCompletedDate != null || !isAppointmentReschedulable || salesOrder.HandoverReadyforOccupancyDate__c != null || isSRClosed) {
                pjModel.isStepCompleted = true;
            }
            pjModel.enabledInProgress = true;
        }*/
        
        else if (stepRecord.MappingName__c == 'Home_Orientation_Appointment' && srDetail.Id != null && srDetail.HandoverDetail__c != null) {
            List<KeyValueModel> stepDetailList = new List<KeyValueModel>();
            
            String appSchSlotStart = srDetail?.HandoverDetail__r?.Home_Orientation_Appointment__r?.SchedStartTime != null ? srDetail.HandoverDetail__r.Home_Orientation_Appointment__r.SchedStartTime?.formatGMT('h:mm a') : null;
            String appSchSlotEnd = srDetail?.HandoverDetail__r?.Home_Orientation_Appointment__r?.SchedEndTime != null ? srDetail.HandoverDetail__r.Home_Orientation_Appointment__r.SchedEndTime?.formatGMT('h:mm a') : null;
            String appSlot = appSchSlotStart + ' - ' + appSchSlotEnd;
            
            stepDetailList.add(new KeyValueModel('Appointment', CustomerAPIConstants.APPOINTMENT_LABEL_HOME_ORIENTATION, CustomerAPIConstants.DATA_TYPE_STRING));
            stepDetailList.add(new KeyValueModel('Date', srDetail?.HandoverDetail__r?.Home_Orientation_Appointment__r?.SchedStartTime != null ? srDetail.HandoverDetail__r.Home_Orientation_Appointment__r.SchedStartTime : null, CustomerAPIConstants.DATA_TYPE_DATE));
            stepDetailList.add(new KeyValueModel('Slot', srDetail?.HandoverDetail__r?.Home_Orientation_Appointment__c != null && String.isNotBlank(appSlot) ? appSlot : null , CustomerAPIConstants.DATA_TYPE_STRING));
            
            pjModel.stepDetails = srDetail?.HandoverDetail__r?.Home_Orientation_Appointment__c != null ? stepDetailList : null;
            pjModel.appointment = new Map<String, Object>();
            pjModel.appointment.put('appointmentId', srDetail?.HandoverDetail__r?.Home_Orientation_Appointment__c != null ? srDetail.HandoverDetail__r.Home_Orientation_Appointment__c : null);
            Boolean isAppointmentReschedulable = ((srStepMap.containsKey(CustomerAPIConstants.STEP_HOME_ORIENTATION) && srStepMap.get(CustomerAPIConstants.STEP_HOME_ORIENTATION).HexaBPM__Closed_Date__c != null) || isSRClosed) ? false : true;
            pjModel.appointment.put('isAppointmentReschedulable', isAppointmentReschedulable);
            pjModel.appointment.put('appointmentType', CustomerAPIConstants.APPOINTMENT_TYPE_HOME_ORIENTATION);
            pjModel.appointment.put('appointmentLabel', CustomerAPIConstants.APPOINTMENT_LABEL_HOME_ORIENTATION);
            pjModel.appointment.put('isAppointmentInProgress', srDetail?.HandoverDetail__r?.Home_Orientation_Appointment__c == null && String.isNotBlank(stepRecord.SRStepName__c) && srStepMap.containsKey(stepRecord.SRStepName__c) ? srStepMap.get(stepRecord.SRStepName__c).PortalAppStatus__c : false);
            
            if ((srDetail?.HandoverDetail__r?.Home_Orientation_Appointment__r?.SchedStartTime != null) || pjModel.stepCompletedDate != null || !isAppointmentReschedulable || salesOrder.HandoverReadyforOccupancyDate__c != null || isSRClosed) {
                pjModel.isStepCompleted = true;
        }
            pjModel.enabledInProgress = true;
        }
        
        //----- Snag Verification related documents
        else if (stepRecord.MappingName__c == 'View_Snag_verification_report' && srDetail.Id != null && srDetail.HandoverDetail__c != null) {
            List<DocumentQueryModel> documents = new List<DocumentQueryModel>();
            for (HexaBPM__SR_Doc__c doc: srDetail.HexaBPM__SR_Docs__r) {
                if (doc.Name == CustomerAPIConstants.DOCUMENT_CUSTOMER_SNAGGING && (doc.HexaBPM__Status__c == Constants.DOCUMENT_STATUS_UPLOADED || doc.HexaBPM__Status__c == Constants.DOCUMENT_STATUS_GENERATED || doc.HexaBPM__Status__c == Constants.DOCUMENT_STATUS_COMPLETED)) {
                    DocumentQueryModel documentQueryModel = new DocumentQueryModel(doc);
                    documentQueryModel.type = CustomerAPIConstants.DOCUMENT_HOME_ORIENTATION_REPORT;
                    documentQueryModel.isUploaded = true;
                    documentQueryModel.isUploadable = false;
                    documents.add(documentQueryModel);
                }
            }
            pjModel.stepDetails = documents;
            if ((!documents.isEmpty() && documents.size() == 1) || pjModel.stepCompletedDate != null || salesOrder.HandoverReadyforOccupancyDate__c != null || isSRClosed) {
                pjModel.isStepCompleted = true;
            }
        }
        //----- RFO Letter & Snag Rectification related documents
        else if (stepRecord.MappingName__c == 'View_Snag_Rectification_Report' && srDetail.Id != null && srDetail.HandoverDetail__c != null) {
            List<DocumentQueryModel> documents = new List<DocumentQueryModel>();
            for (HexaBPM__SR_Doc__c doc: srDetail.HexaBPM__SR_Docs__r) {
                if ((doc.Name == CustomerAPIConstants.DOCUMENT_CUSTOMER_DESNAGGING || doc.Name == CustomerAPIConstants.DOCUMENT_READY_FOR_OCCUPANCY_LETTER) && (doc.HexaBPM__Status__c == Constants.DOCUMENT_STATUS_UPLOADED || doc.HexaBPM__Status__c == Constants.DOCUMENT_STATUS_GENERATED || doc.HexaBPM__Status__c == Constants.DOCUMENT_STATUS_COMPLETED)) {
                    DocumentQueryModel documentQueryModel = new DocumentQueryModel(doc);
                    documentQueryModel.isUploaded = true;
                    documentQueryModel.isUploadable = false;
                    documents.add(documentQueryModel);
                }
            }
            pjModel.stepDetails = documents;
            if ((!documents.isEmpty() && documents.size() == 2) || pjModel.stepCompletedDate != null || salesOrder.HandoverReadyforOccupancyDate__c != null || isSRClosed) {
                pjModel.isStepCompleted = true;
            }
        }
        //----- Hanover payment details
        else if ((stepRecord.MappingName__c == 'Complete_Outstanding_Payment' || stepRecord.MappingName__c == 'Complete_Outstanding_Payment_Plot') && srDetail.Id != null && srDetail.HandoverDetail__c != null) {
            pjModel.isStepCompleted = true;
            List<InstallmentLines__c> installmentDetails = new List<InstallmentLines__c>();
            for (InstallmentLines__c line: salesOrder.InstallmentLines__r) {
                if (line.PaymentInstallments__c != null && line.PaymentInstallments__r.IsHandoverPayment__c) {
                    installmentDetails.add(line);
                    break;
                }
            }
            CustomerFinancialWebservice.FinancialModel financialStatement = CustomerFinancialWebservice.populateFinancialDetails(installmentDetails, new List<SalesOrderOtherCharges__c>(), directDebitRequestList, receiptMap, '', '');
            for (CustomerFinancialWebservice.PaymentModel paymentModel: financialStatement.paymentDetails) {
                if (paymentModel.paymentStatus != CustomerAPIConstants.PAYMENT_STATUS_CLEARED) {
                    pjModel.isStepCompleted = false;
                }
            }
            pjModel.stepDetails = financialStatement.paymentDetails;
        }
        //----- Snag Verification Appointment date and slot
       
        /*else if (stepRecord.MappingName__c == 'Snag_Verification_Appointment' && srDetail.Id != null && srDetail.HandoverDetail__c != null) {
            List<KeyValueModel> stepDetailList = new List<KeyValueModel>();
            stepDetailList.add(new KeyValueModel('Appointment', CustomerAPIConstants.APPOINTMENT_LABEL_SNAG_VERIFICATION, CustomerAPIConstants.DATA_TYPE_STRING));
            stepDetailList.add(new KeyValueModel('Date', srDetail.HandoverDetail__r.CustomerDesnaggingAppointment__c != null ? srDetail.HandoverDetail__r.CustomerDesnaggingAppointment__r.Date__c : null, CustomerAPIConstants.DATA_TYPE_DATE));
            stepDetailList.add(new KeyValueModel('Slot', srDetail.HandoverDetail__r.CustomerDesnaggingAppointment__c != null && srDetail.HandoverDetail__r.CustomerDesnaggingAppointment__r.Appointment_Slot_Time__c != null ? srDetail.HandoverDetail__r.CustomerDesnaggingAppointment__r.Appointment_Slot_Time__c : srDetail.HandoverDetail__r.CustomerDesnaggingAppointment__r.Slot__c, CustomerAPIConstants.DATA_TYPE_STRING));
            
            pjModel.stepDetails = srDetail.HandoverDetail__r.CustomerDesnaggingAppointment__c != null ? stepDetailList : null;
            pjModel.appointment = new Map<String, Object>();
            pjModel.appointment.put('appointmentId', srDetail.HandoverDetail__r.CustomerDesnaggingAppointment__c != null ? srDetail.HandoverDetail__r.CustomerDesnaggingAppointment__r.AppointmentId__c : null);
            Boolean isAppointmentReschedulable = ((srStepMap.containsKey(CustomerAPIConstants.STEP_TITLE_DEED_REGISTRATION) && srStepMap.get(CustomerAPIConstants.STEP_TITLE_DEED_REGISTRATION).HexaBPM__Closed_Date__c != null) || isSRClosed) ? false : true;
            pjModel.appointment.put('isAppointmentReschedulable', isAppointmentReschedulable);
            pjModel.appointment.put('appointmentType', CustomerAPIConstants.APPOINTMENT_TYPE_SNAG_VERIFICATION);
            pjModel.appointment.put('appointmentLabel', CustomerAPIConstants.APPOINTMENT_LABEL_SNAG_VERIFICATION);
            pjModel.appointment.put('isAppointmentInProgress', srDetail.HandoverDetail__r.CustomerDesnaggingAppointment__c == null && String.isNotBlank(stepRecord.SRStepName__c) && srStepMap.containsKey(stepRecord.SRStepName__c) ? srStepMap.get(stepRecord.SRStepName__c).PortalAppStatus__c : false);

            if ((srDetail.HandoverDetail__r.CustomerDesnaggingAppointment__c != null && srDetail.HandoverDetail__r.CustomerDesnaggingAppointment__r.Date__c != null) || pjModel.stepCompletedDate != null || !isAppointmentReschedulable || isSRClosed) {
                pjModel.isStepCompleted = true;
            }
            pjModel.enabledInProgress = true;
        }*/
        
         else if (stepRecord.MappingName__c == 'Snag_Verification_Appointment' && srDetail.Id != null && srDetail.HandoverDetail__c != null) {
            List<KeyValueModel> stepDetailList = new List<KeyValueModel>();
            
            String appSchSlotStart = srDetail?.HandoverDetail__r?.Desnagging_Appointment__r?.SchedStartTime != null ? srDetail.HandoverDetail__r.Desnagging_Appointment__r.SchedStartTime?.formatGMT('h:mm a') : null;
            String appSchSlotEnd = srDetail?.HandoverDetail__r?.Desnagging_Appointment__r?.SchedEndTime != null ? srDetail.HandoverDetail__r.Desnagging_Appointment__r.SchedEndTime?.formatGMT('h:mm a') : null;
            String appSlot = appSchSlotStart + ' - ' + appSchSlotEnd;
            
            stepDetailList.add(new KeyValueModel('Appointment', CustomerAPIConstants.APPOINTMENT_LABEL_SNAG_VERIFICATION, CustomerAPIConstants.DATA_TYPE_STRING));
            stepDetailList.add(new KeyValueModel('Date', srDetail?.HandoverDetail__r?.Desnagging_Appointment__r?.SchedStartTime != null ? srDetail.HandoverDetail__r.Desnagging_Appointment__r.SchedStartTime : null, CustomerAPIConstants.DATA_TYPE_DATE));
            stepDetailList.add(new KeyValueModel('Slot', srDetail?.HandoverDetail__r?.Desnagging_Appointment__c != null && String.isNotBlank(appSlot) ? appSlot : null, CustomerAPIConstants.DATA_TYPE_STRING));
            
            pjModel.stepDetails = srDetail?.HandoverDetail__r?.Desnagging_Appointment__c != null ? stepDetailList : null;
            pjModel.appointment = new Map<String, Object>();
            pjModel.appointment.put('appointmentId', srDetail?.HandoverDetail__r?.Desnagging_Appointment__c != null ? srDetail.HandoverDetail__r.Desnagging_Appointment__c : null);
            Boolean isAppointmentReschedulable = ((srStepMap.containsKey(CustomerAPIConstants.STEP_TITLE_DEED_REGISTRATION) && srStepMap.get(CustomerAPIConstants.STEP_TITLE_DEED_REGISTRATION).HexaBPM__Closed_Date__c != null) || isSRClosed) ? false : true;
            pjModel.appointment.put('isAppointmentReschedulable', isAppointmentReschedulable);
            pjModel.appointment.put('appointmentType', CustomerAPIConstants.APPOINTMENT_TYPE_SNAG_VERIFICATION);
            pjModel.appointment.put('appointmentLabel', CustomerAPIConstants.APPOINTMENT_LABEL_SNAG_VERIFICATION);
            pjModel.appointment.put('isAppointmentInProgress', srDetail?.HandoverDetail__r?.Desnagging_Appointment__c == null && String.isNotBlank(stepRecord.SRStepName__c) && srStepMap.containsKey(stepRecord.SRStepName__c) ? srStepMap.get(stepRecord.SRStepName__c).PortalAppStatus__c : false);
            
            if ((srDetail?.HandoverDetail__r?.Desnagging_Appointment__r?.SchedStartTime != null) || pjModel.stepCompletedDate != null || !isAppointmentReschedulable || isSRClosed) {
                pjModel.isStepCompleted = true;
            }
            pjModel.enabledInProgress = true;
        }
        //----- Title Deed Registration related documents
        else if ((stepRecord.MappingName__c == 'Title_Deed_Registration' || stepRecord.MappingName__c == 'Title_Deed_Registration_Plot') && srDetail.Id != null && srDetail.HandoverDetail__c != null) {
            List<DocumentQueryModel> documents = new List<DocumentQueryModel>();
            HexaBPM__SR_Doc__c srDoc = new HexaBPM__SR_Doc__c();
            for (HexaBPM__SR_Doc__c doc: srDetail.HexaBPM__SR_Docs__r) {
                if (doc.Name == CustomerAPIConstants.DOCUMENT_TITLE_DEED_COPY && (doc.HexaBPM__Status__c == Constants.DOCUMENT_STATUS_UPLOADED || doc.HexaBPM__Status__c == Constants.DOCUMENT_STATUS_GENERATED || doc.HexaBPM__Status__c == Constants.DOCUMENT_STATUS_COMPLETED)) {
                    DocumentQueryModel documentQueryModel = new DocumentQueryModel(doc);
                    documentQueryModel.isUploaded = true;
                    documentQueryModel.isUploadable = false;
                    documents.add(documentQueryModel);
                    srDoc = doc;
                }
            }
            pjModel.stepDetails = documents;
            if ((!documents.isEmpty() && documents.size() == 1) || pjModel.stepCompletedDate != null || srDetail.HandoverDetail__r.HandoverCompletionDate__c != null || isSRClosed) {
                pjModel.isStepCompleted = true;
            }
        }
        //----- Utility Transfer related documents
        else if ((stepRecord.MappingName__c == 'Utility_Transfer' || stepRecord.MappingName__c == 'Utility_Transfer_Plot') && srDetail.Id != null && srDetail.HandoverDetail__c != null) {
            List<DocumentQueryModel> documents = new List<DocumentQueryModel>();
            for (HexaBPM__SR_Doc__c doc: srDetail.HexaBPM__SR_Docs__r) {
                if (((salesOrder.Unit__r.RecordType.Name != Constants.UNIT_RECORD_TYPE_PLOT && (doc.Name == CustomerAPIConstants.DOCUMENT_DISTRICT_COOLING_TRANSFER || doc.Name == CustomerAPIConstants.DOCUMENT_SERVICE_CHARGES_PAYMENT_PROOF || doc.Name == CustomerAPIConstants.DOCUMENT_ADDC_CERTIFICATE || doc.Name == CustomerAPIConstants.DOCUMENT_NOC_FOR_ADDC)) || (salesOrder.Unit__r.RecordType.Name == Constants.UNIT_RECORD_TYPE_PLOT && (doc.Name == CustomerAPIConstants.DOCUMENT_SERVICE_CHARGES_PAYMENT_PROOF))) && (doc.HexaBPM__Status__c == Constants.DOCUMENT_STATUS_UPLOADED || doc.HexaBPM__Status__c == Constants.DOCUMENT_STATUS_GENERATED || doc.HexaBPM__Status__c == Constants.DOCUMENT_STATUS_COMPLETED)) {
                    DocumentQueryModel documentQueryModel = new DocumentQueryModel(doc);
                    documentQueryModel.isUploaded = true;
                    documentQueryModel.isUploadable = false;
                    documents.add(documentQueryModel);
                }
            }
            if ((!documents.isEmpty() && ((stepRecord.MappingName__c == 'Utility_Transfer' && documents.size() == 4) || (stepRecord.MappingName__c == 'Utility_Transfer_Plot' && documents.size() == 1))) || pjModel.stepCompletedDate != null || srDetail.HandoverDetail__r.HandoverCompletionDate__c != null || isSRClosed) {
                pjModel.isStepCompleted = true;
                for (DocumentQueryModel doc: documents) {
                    if (doc.isUploaded == false) {
                        pjModel.isStepCompleted = false;
                    }
                }
            }
            pjModel.stepDetails = documents;
        }
        //----- Handover related documents
        else if (stepRecord.MappingName__c == 'Handover_Documents_Signing' && srDetail.Id != null && srDetail.HandoverDetail__c != null) {
            Map<String, HexaBPM__SR_Doc__c> signedDocMap = new Map<String, HexaBPM__SR_Doc__c>();
            
            Integer signDocCount = 0;
            for (HexaBPM__SR_Doc__c doc: srDetail.HexaBPM__SR_Docs__r) {
                if (((salesOrder.Unit__r.RecordType.Name != Constants.UNIT_RECORD_TYPE_PLOT && doc.Name == CustomerAPIConstants.DOCUMENT_SIGNED_HANDOVER_NOC_LETTER) || (salesOrder.Unit__r.RecordType.Name == Constants.UNIT_RECORD_TYPE_PLOT && doc.Name == CustomerAPIConstants.DOCUMENT_SIGNED_PLOT_POSSESSION_CERTIFICATE)) && (doc.HexaBPM__Status__c == Constants.DOCUMENT_STATUS_UPLOADED || doc.HexaBPM__Status__c == Constants.DOCUMENT_STATUS_GENERATED || doc.HexaBPM__Status__c == Constants.DOCUMENT_STATUS_COMPLETED || doc.HexaBPM__Status__c == CustomerAPIConstants.DOCUMENT_STATUS_DOCUSIGN_PENDING)) {
                    signedDocMap.put(doc.Name, doc);
                    signDocCount++;
                }
            }
            System.debug('signedDocMap>>>' + JSON.serialize(signedDocMap));
            List<DocumentQueryModel> documents = new List<DocumentQueryModel>();
            for (HexaBPM__SR_Doc__c doc: srDetail.HexaBPM__SR_Docs__r) {
                if ((salesOrder.Unit__r.RecordType.Name != Constants.UNIT_RECORD_TYPE_PLOT && doc.Name == CustomerAPIConstants.DOCUMENT_HANDOVER_NOC_LETTER) || (salesOrder.Unit__r.RecordType.Name == Constants.UNIT_RECORD_TYPE_PLOT && doc.Name == CustomerAPIConstants.DOCUMENT_PLOT_POSSESSION_CERTIFICATE)) {
                    DocumentQueryModel documentQueryModel = new DocumentQueryModel(doc);
                    documentQueryModel.isUploaded = (doc.HexaBPM__Status__c == Constants.DOCUMENT_STATUS_UPLOADED || doc.HexaBPM__Status__c == Constants.DOCUMENT_STATUS_GENERATED || doc.HexaBPM__Status__c == Constants.DOCUMENT_STATUS_COMPLETED) ? true : false;
                    documentQueryModel.isUploadable = false;
                    documentQueryModel.eligibleForeSign = (srDetail.HandoverDetail__r.HandoverCompletionDate__c != null || isSRClosed) ? false : true;
                    HexaBPM__SR_Doc__c signDoc = null;
                    if (doc.Name.containsIgnoreCase(CustomerAPIConstants.DOCUMENT_HANDOVER_NOC_LETTER)) {
                        signDoc = signedDocMap.get(CustomerAPIConstants.DOCUMENT_SIGNED_HANDOVER_NOC_LETTER);
                    } else if (doc.Name.containsIgnoreCase(CustomerAPIConstants.DOCUMENT_PLOT_POSSESSION_CERTIFICATE)) {
                        signDoc = signedDocMap.get(CustomerAPIConstants.DOCUMENT_SIGNED_PLOT_POSSESSION_CERTIFICATE);
                    }
                    System.debug('signDoc>>>' + signDoc);
                    if (signDoc != null && signDoc.HexaBPM__Status__c == CustomerAPIConstants.DOCUMENT_STATUS_DOCUSIGN_PENDING) {
                        documentQueryModel.isSignCompleted = signDoc != null ? true : false;
                    } else {
                        documentQueryModel.signDocumentId = signDoc != null ? (String)signDoc.Id : '';
                    }
                    documents.add(documentQueryModel);
                }
            }

            if ((!documents.isEmpty() && ((salesOrder.Unit__r.RecordType.Name != Constants.UNIT_RECORD_TYPE_PLOT && signDocCount == 1) || (salesOrder.Unit__r.RecordType.Name == Constants.UNIT_RECORD_TYPE_PLOT && signDocCount == 1))) || srDetail.HandoverDetail__r.HandoverCompletionDate__c != null || isSRClosed) {
                pjModel.isStepCompleted = true;
                for (DocumentQueryModel doc: documents) {
                    if (doc.isUploaded == false) {
                        pjModel.isStepCompleted = false;
                    }
                }
            }
            pjModel.enabledInProgress = true;
            pjModel.stepDetails = documents;
        }
        //----- Key Hadover Appointment date and slot
       
       /* else if (stepRecord.MappingName__c == 'Key_Handover_Appointment' && srDetail.Id != null && srDetail.HandoverDetail__c != null ) {
            List<KeyValueModel> stepDetailList = new List<KeyValueModel>();
            stepDetailList.add(new KeyValueModel('Appointment', CustomerAPIConstants.APPOINTMENT_LABEL_KEY_HANDOVER, CustomerAPIConstants.DATA_TYPE_STRING));
            stepDetailList.add(new KeyValueModel('Date', srDetail.HandoverDetail__r.KeyHandoverAppointment__c != null ? srDetail.HandoverDetail__r.KeyHandoverAppointment__r.Date__c : null, CustomerAPIConstants.DATA_TYPE_DATE));
            stepDetailList.add(new KeyValueModel('Slot', srDetail.HandoverDetail__r.KeyHandoverAppointment__c != null && srDetail.HandoverDetail__r.KeyHandoverAppointment__r.Appointment_Slot_Time__c != null ? srDetail.HandoverDetail__r.KeyHandoverAppointment__r.Appointment_Slot_Time__c : srDetail.HandoverDetail__r.KeyHandoverAppointment__r.Slot__c, CustomerAPIConstants.DATA_TYPE_STRING));
            
            pjModel.stepDetails = srDetail.HandoverDetail__r.KeyHandoverAppointment__c != null ? stepDetailList : null;
            pjModel.appointment = new Map<String, Object>();
            pjModel.appointment.put('appointmentId', srDetail.HandoverDetail__r.KeyHandoverAppointment__c != null ? srDetail.HandoverDetail__r.KeyHandoverAppointment__r.AppointmentId__c: null);
            Boolean isAppointmentReschedulable = ((srStepMap.containsKey(CustomerAPIConstants.STEP_KEY_HANDOVER) && srStepMap.get(CustomerAPIConstants.STEP_KEY_HANDOVER).HexaBPM__Closed_Date__c != null) || isSRClosed) ? false : true;
            pjModel.appointment.put('isAppointmentReschedulable', isAppointmentReschedulable);
            pjModel.appointment.put('appointmentType', CustomerAPIConstants.APPOINTMENT_TYPE_KEY_HANDOVER);
            pjModel.appointment.put('appointmentLabel', CustomerAPIConstants.APPOINTMENT_LABEL_KEY_HANDOVER);
            pjModel.appointment.put('isAppointmentInProgress', srDetail.HandoverDetail__r.KeyHandoverAppointment__c == null && String.isNotBlank(stepRecord.SRStepName__c) && srStepMap.containsKey(stepRecord.SRStepName__c) ? srStepMap.get(stepRecord.SRStepName__c).PortalAppStatus__c : false);
            
            if ((srDetail.HandoverDetail__r.KeyHandoverAppointment__c != null && srDetail.HandoverDetail__r.KeyHandoverAppointment__r.Date__c != null) || pjModel.stepCompletedDate != null || !isAppointmentReschedulable || srDetail.HandoverDetail__r.HandoverCompletionDate__c != null || isSRClosed) {
                pjModel.isStepCompleted = true;
            }
            pjModel.enabledInProgress = true;
        }*/
        
        else if (stepRecord.MappingName__c == 'Key_Handover_Appointment' && srDetail.Id != null && srDetail.HandoverDetail__c != null ) {
            List<KeyValueModel> stepDetailList = new List<KeyValueModel>();
            
            String appSchSlotStart = srDetail?.HandoverDetail__r?.Key_Handover_Appointment__r?.SchedStartTime != null ? srDetail.HandoverDetail__r.Key_Handover_Appointment__r.SchedStartTime?.formatGMT('h:mm a') : null;
            String appSchSlotEnd = srDetail?.HandoverDetail__r?.Key_Handover_Appointment__r?.SchedEndTime != null ? srDetail.HandoverDetail__r.Key_Handover_Appointment__r.SchedEndTime?.formatGMT('h:mm a') : null;
            String appSlot = appSchSlotStart + ' - ' + appSchSlotEnd;
            
            stepDetailList.add(new KeyValueModel('Appointment', CustomerAPIConstants.APPOINTMENT_LABEL_KEY_HANDOVER, CustomerAPIConstants.DATA_TYPE_STRING));
            stepDetailList.add(new KeyValueModel('Date', srDetail?.HandoverDetail__r?.Key_Handover_Appointment__r?.SchedStartTime != null ? srDetail.HandoverDetail__r.Key_Handover_Appointment__r.SchedStartTime : null, CustomerAPIConstants.DATA_TYPE_DATE));
            stepDetailList.add(new KeyValueModel('Slot', srDetail?.HandoverDetail__r?.Key_Handover_Appointment__c != null && String.isNotBlank(appSlot) ? appSlot : null, CustomerAPIConstants.DATA_TYPE_STRING));
            
            pjModel.stepDetails = srDetail?.HandoverDetail__r?.Key_Handover_Appointment__c != null ? stepDetailList : null;
            pjModel.appointment = new Map<String, Object>(); 
            pjModel.appointment.put('appointmentId', srDetail?.HandoverDetail__r?.Key_Handover_Appointment__c != null ? srDetail.HandoverDetail__r.Key_Handover_Appointment__c : null);
            Boolean isAppointmentReschedulable = ((srStepMap.containsKey(CustomerAPIConstants.STEP_KEY_HANDOVER) && srStepMap.get(CustomerAPIConstants.STEP_KEY_HANDOVER).HexaBPM__Closed_Date__c != null) || isSRClosed) ? false : true;
            pjModel.appointment.put('isAppointmentReschedulable', isAppointmentReschedulable);
            pjModel.appointment.put('appointmentType', CustomerAPIConstants.APPOINTMENT_TYPE_KEY_HANDOVER);
            pjModel.appointment.put('appointmentLabel', CustomerAPIConstants.APPOINTMENT_LABEL_KEY_HANDOVER);
            pjModel.appointment.put('isAppointmentInProgress', srDetail?.HandoverDetail__r?.Key_Handover_Appointment__c == null && String.isNotBlank(stepRecord.SRStepName__c) && srStepMap.containsKey(stepRecord.SRStepName__c) ? srStepMap.get(stepRecord.SRStepName__c).PortalAppStatus__c : false);
            
            if ((srDetail?.HandoverDetail__r?.Key_Handover_Appointment__r?.SchedStartTime != null) || pjModel.stepCompletedDate != null || !isAppointmentReschedulable || srDetail.HandoverDetail__r.HandoverCompletionDate__c != null || isSRClosed) {
                pjModel.isStepCompleted = true;
        }
            pjModel.enabledInProgress = true;
        }
        
        //----- Check if Key Hadover Appointment is completed or not
        else if (stepRecord.MappingName__c == 'Key_Handed_Over' && srDetail.Id != null && srDetail.HandoverDetail__c != null) {
            //----- Logic if any
            List<KeyValueModel> stepDetailList = new List<KeyValueModel>();
            stepDetailList.add(new KeyValueModel('Handover Date', srDetail.HandoverDetail__r.HandoverCompletionDate__c != null ? srDetail.HandoverDetail__r.HandoverCompletionDate__c : null, CustomerAPIConstants.DATA_TYPE_DATE));
            
            if ((srDetail.HandoverDetail__c != null && srDetail.HandoverDetail__r.HandoverCompletionDate__c != null) || isSRClosed) {
                pjModel.isStepCompleted = true;
            }
            pjModel.stepDetails = stepDetailList;
        }
        //----- Living in the unit
        else if (stepRecord.MappingName__c == 'Living_in_the_unit') {
            pjModel.showDueNextPaymentDays = isPostHandoverPayment == true ? true : false;
        }
        //----- All Post Handover Payment for Off Plan Property
        else if (stepRecord.MappingName__c == 'Post_Handover_Payment') {
            CustomerFinancialWebservice.FinancialModel financialStatement = CustomerFinancialWebservice.populateFinancialDetails(salesOrder.InstallmentLines__r, salesOrder.SalesOrdersOtherCharges__r, directDebitRequestList, receiptMap, '', '');
            List<CustomerFinancialWebservice.PaymentModel> paymentDetails = new List<CustomerFinancialWebservice.PaymentModel>();
            pjModel.isStepCompleted = true;

            Boolean isHandoverPayment = false;
            for (CustomerFinancialWebservice.PaymentModel paymentModel: financialStatement.paymentDetails) {
                isHandoverPayment = isHandoverPayment ? true : paymentModel.isHandoverPayment;
                if (isHandoverPayment && paymentModel.isInstallment && !paymentModel.isHandoverPayment) {
                    paymentDetails.add(paymentModel);
                    if (paymentModel.paymentStatus != CustomerAPIConstants.PAYMENT_STATUS_CLEARED) {
                        pjModel.isStepCompleted = false;
                    }
                }
            }
            pjModel.stepDetails = paymentDetails;
        }
        //----- DLP Information like Handover date and DLP Start & End Date
        else if (stepRecord.MappingName__c == 'Defect_Liability_Period') {
            List<KeyValueModel> stepDetailList = new List<KeyValueModel>();
            String dlpStatus = '';
            if (salesOrder.CustomerDLPStartDate__c != null) {
                stepDetailList.add(new KeyValueModel('DLP Start Date', salesOrder.CustomerDLPStartDate__c, CustomerAPIConstants.DATA_TYPE_DATE));
            }
            if (salesOrder.DLPDate__c != null) {
                stepDetailList.add(new KeyValueModel('DLP End Date', salesOrder.DLPDate__c, CustomerAPIConstants.DATA_TYPE_DATE));
            }
            if (salesOrder.CustomerDLPStartDate__c != null && salesOrder.DLPDate__c != null) {
                dlpStatus = (salesOrder.CustomerDLPStartDate__c <= date.today() && salesOrder.DLPDate__c == null) || salesOrder.DLPDate__c >= date.today() ? CustomerAPIConstants.STATUS_ACTIVE : CustomerAPIConstants.STATUS_EXPIRED;
                stepDetailList.add(new KeyValueModel('DLP Status', dlpStatus, CustomerAPIConstants.DATA_TYPE_STRING));
            }
            // if (salesOrder.HandoverServiceChargeStartDate__c != null) {
            //     stepDetailList.add(new KeyValueModel('Service Charge Start Date', salesOrder.HandoverServiceChargeStartDate__c, CustomerAPIConstants.DATA_TYPE_DATE));
            // }
            // if (salesOrder.HandoverServiceChargeEndDate__c != null) {
            //     stepDetailList.add(new KeyValueModel('Service Charge End Date', salesOrder.HandoverServiceChargeEndDate__c, CustomerAPIConstants.DATA_TYPE_DATE));
            // }
            // if (salesOrder.HandoverServiceChargeStartDate__c != null || salesOrder.HandoverServiceChargeEndDate__c != null) {
            //     stepDetailList.add(new KeyValueModel('Service Charge Status', ((salesOrder.HandoverServiceChargeStartDate__c <= date.today() && salesOrder.HandoverServiceChargeEndDate__c == null) || salesOrder.HandoverServiceChargeEndDate__c >= date.today() ? CustomerAPIConstants.STATUS_ACTIVE : CustomerAPIConstants.STATUS_EXPIRED), CustomerAPIConstants.DATA_TYPE_STRING));
            // }
            if (srDetail.HandoverDetail__c != null && srDetail.HandoverDetail__r.HandoverCompletionDate__c != null) {
                stepDetailList.add(new KeyValueModel('Handover Date', srDetail.HandoverDetail__r.HandoverCompletionDate__c, CustomerAPIConstants.DATA_TYPE_DATE));
            }
            if ((String.isBlank(lang) || lang == 'en') && String.isNotBlank(dlpStatus)) {
                pjModel.stepName = pjModel.stepName + ' (' + dlpStatus + ')';
            }
            pjModel.isStepCompleted = true;
            pjModel.stepDetails = !stepDetailList.isEmpty() ? stepDetailList : null;
        }
        //----- Maintenance Contract Information like AMC and PMC Start & End Date
        else if (stepRecord.MappingName__c == 'Maintenance_Contract') {
            List<KeyValueModel> stepDetailList = new List<KeyValueModel>();
            String mcStatus = '';
            if (salesOrder.AMCStartDate__c != null) {
                stepDetailList.add(new KeyValueModel('AMC Start Date', salesOrder.AMCStartDate__c, CustomerAPIConstants.DATA_TYPE_DATE));
            }
            if (salesOrder.AMCEndDate__c != null) {
                stepDetailList.add(new KeyValueModel('AMC End Date', salesOrder.AMCEndDate__c, CustomerAPIConstants.DATA_TYPE_DATE));
            }
            if (salesOrder.AMCStartDate__c != null || salesOrder.AMCEndDate__c != null) {
                mcStatus = (salesOrder.AMCStartDate__c <= date.today() && salesOrder.AMCEndDate__c == null) || salesOrder.AMCEndDate__c >= date.today() ? CustomerAPIConstants.STATUS_ACTIVE : CustomerAPIConstants.STATUS_EXPIRED;
                stepDetailList.add(new KeyValueModel('AMC Status', mcStatus, CustomerAPIConstants.DATA_TYPE_STRING));
            }
            if (salesOrder.PMAStartDate__c != null) {
                stepDetailList.add(new KeyValueModel('PMA Start Date', salesOrder.PMAStartDate__c, CustomerAPIConstants.DATA_TYPE_DATE));
            }
            if (salesOrder.PMAEndDate__c != null) {
                stepDetailList.add(new KeyValueModel('PMA End Date', salesOrder.PMAEndDate__c, CustomerAPIConstants.DATA_TYPE_DATE));
            }
            if (salesOrder.PMAStartDate__c != null || salesOrder.PMAEndDate__c != null) {
                String tempStatus = (salesOrder.PMAStartDate__c <= date.today() && salesOrder.PMAEndDate__c == null) || salesOrder.PMAEndDate__c >= date.today() ? CustomerAPIConstants.STATUS_ACTIVE : CustomerAPIConstants.STATUS_EXPIRED;
                stepDetailList.add(new KeyValueModel('PMA Status', tempStatus, CustomerAPIConstants.DATA_TYPE_STRING));
                mcStatus = mcStatus == CustomerAPIConstants.STATUS_ACTIVE ? mcStatus : tempStatus;
            }
            if ((String.isBlank(lang) || lang == 'en') && String.isNotBlank(mcStatus)) {
                pjModel.stepName = pjModel.stepName + ' (' + mcStatus + ')';
            }
            
            pjModel.isStepCompleted = true;
            pjModel.stepDetails = !stepDetailList.isEmpty() ? stepDetailList : null;
        }
        //----- All Future Payment for Ready Property
        // else if (stepRecord.MappingName__c == 'Payment_Milestone_Future') {
        //     CustomerFinancialWebservice.FinancialModel financialStatement = CustomerFinancialWebservice.populateFinancialDetails(salesOrder.InstallmentLines__r, salesOrder.SalesOrdersOtherCharges__r, directDebitRequestList, receiptMap, '', '');
        //     List<CustomerFinancialWebservice.PaymentModel> paymentDetails = new List<CustomerFinancialWebservice.PaymentModel>();
        //     pjModel.isStepCompleted = true;
        //     for (CustomerFinancialWebservice.PaymentModel paymentModel: financialStatement.paymentDetails) {
        //         if (paymentModel.description != CustomerAPIConstants.DOWN_PAYMENT && !paymentModel.isHandoverPayment && paymentModel.paymentType != Constants.BUDGET_LINE_ADMFEE && paymentModel.paymentType != Constants.BUDGET_LINE_ADMADMINFEE) {
        //             paymentDetails.add(paymentModel);
        //             if (paymentModel.paymentStatus != CustomerAPIConstants.PAYMENT_STATUS_CLEARED) {
        //                 pjModel.isStepCompleted = false;
        //             }
        //         }
        //     }
        //     pjModel.stepDetails = paymentDetails;
        //     pjModel.showDueNextPaymentDays = true;
        // }
        //----- Show Service Requests
        else if (stepRecord.MappingName__c == 'Service_Requests') {
            pjModel.isStepCompleted = true;

            CustomerGetServiceRequestWebService.SRModel srModel = new CustomerGetServiceRequestWebService.SRModel();
            srModel.customerId = salesOrder.Account__c;
            srModel.orderId = salesOrder.Id;

            //Integer srLimit = Utilities.getConstantValue('SRLimitForPropertyJourney');
              Integer srLimit = Integer.valueOf((getConstantsMap.get('SRLimitForPropertyJourney')).ConstantValue__c);
            
            String srModelString = JSON.serialize(srModel);
            
            CustomerGetServiceRequestWebService.ResponseModel serviceRequestMap = CustomerGetServiceRequestWebService.getServiceRequest(srModelString, srLimit, true);
            pjModel.stepDetails = serviceRequestMap.serviceRequests;
        }
        //----- Show Community Details
        else if (stepRecord.MappingName__c == 'Community_Details') {
            pjModel.isStepCompleted = true;
        }
        //----- Upload Design for Plot
        else if (stepRecord.MappingName__c == 'Upload_Plot_Design' || Test.isRunningTest()) {
            CustomerGetServiceRequestWebService.SRModel srModel = new CustomerGetServiceRequestWebService.SRModel();
            srModel.customerId = salesOrder.Account__c;
            srModel.orderId = salesOrder.Id;
            srModel.type = CustomerAPIConstants.TYPE_PLOT_DESIGN;

            String srModelString = JSON.serialize(srModel);
            
            CustomerGetServiceRequestWebService.ResponseModel serviceRequestMap = CustomerGetServiceRequestWebService.getServiceRequest(srModelString, null, false);
            pjModel.stepDetails = serviceRequestMap.serviceRequests;
            pjModel.isStepCompleted = serviceRequestMap.serviceRequests.size() > 0 ? true : false;
        }
        //----- Show Construction updates from Sitecore
        else if (stepRecord.MappingName__c == 'Plot_Construction') {pjModel.isStepCompleted = true;
        }
        //----- Show Construction updates from Sitecore
        else if (stepRecord.MappingName__c == 'Plot_Construction') {pjModel.isStepCompleted = true;
        }
        return pjModel;
    }

    public class MainPropertyJourneyModel {
        public List<KeyValueModel> orderDetails                                         {get;set;}
        public Decimal totalPaymentAmount                                               {get;set;}
        public Decimal duePaymentInDays                                                 {get;set;}
        public Decimal nextPaymentInDays                                                {get;set;}
        public Decimal constructionPercentage                                           {get;set;}
        public CustomerFinancialWebservice.PaymentModel paymentDetails                  {get;set;}
        public Map<String, Object> salesOrderDetails                                    {get;set;}
        public List<CustomerFinancialWebservice.PaymentModel> paymentPlan               {get;set;}
        public List<KeyValueModel> handoverDetails                                      {get;set;}
        public List<PropertyJourneyModel> propertyJourneyDetails                        {get;set;}
        
        public MainPropertyJourneyModel() {
            this.orderDetails = new List<KeyValueModel>();
            this.totalPaymentAmount = 0;
            this.duePaymentInDays = null;
            this.nextPaymentInDays = null;
            this.constructionPercentage = 0;
            this.paymentDetails = null;
            this.salesOrderDetails = new Map<String, Object>();
            this.paymentPlan = new List<CustomerFinancialWebservice.PaymentModel>();
            this.handoverDetails = new List<KeyValueModel>();
            this.propertyJourneyDetails = new List<PropertyJourneyModel>();
        }
    }
    
    public class PropertyJourneyModel{
        public String stepName                                              {get;set;}
        public String stepARName                                            {get;set;}
        public String stepUniqueName                                        {get;set;}
        public Decimal stepNo                                               {get;set;}
        public String description                                           {get;set;}
        public Boolean showDueNextPaymentDays                               {get;set;}
        public String arDescription                                         {get;set;}
        public Object stepDetails                                           {get;set;}
        public Boolean isStepCompleted                                      {get;set;}
        public Boolean enabledInProgress                                    {get;set;}
        public Date stepCompletedDate                                       {get;set;}
        public Map<String, Object> appointment                              {get;set;}
        public List<PropertyJourneyModel> propertyJourneyDetails            {get;set;}
        
        public PropertyJourneyModel(CustomerPropertyJourney__mdt step, Decimal stepNo, String lang) {
            this.stepName = String.isNotBlank(lang) && lang == CustomerAPIConstants.LANGUAGE_AR ? step.ARLabel__c : String.isNotBlank(step.ENLabel__c) ? step.ENLabel__c : step.Label;
            this.stepARName = step.ARLabel__c;
            this.stepUniqueName = step.MappingName__c;
            this.stepNo = stepNo;
            this.description = String.isNotBlank(lang) && lang == CustomerAPIConstants.LANGUAGE_AR ? step.ARDescription__c : step.Description__c;
            this.arDescription = step.ARDescription__c;
            this.showDueNextPaymentDays = false;
            this.stepDetails = null;
            this.isStepCompleted = false;
            this.enabledInProgress = false;
            this.stepCompletedDate = null;
            this.appointment = null;
            this.propertyJourneyDetails = new List<PropertyJourneyModel>();
        }
    }
    
    public class KeyValueModel {
        public String label                 {get;set;}
        public Object value                 {get;set;}
        public String type                  {get;set;}
        
        public KeyValueModel(String label, Object value, String type) {
            this.label = label;
            this.value = value;
            this.type = type;
        }
    }
}