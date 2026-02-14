import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import Restrict_DD_Request_On_IBAN_Validation from '@salesforce/label/c.Restrict_DD_Request_On_IBAN_Validation';
import Restrict_IBAN_Verification from '@salesforce/label/c.Restrict_IBAN_Verification';
import getSalesOrderAccountDetailsList from '@salesforce/apex/DirectDebitService.getSalesOrderAccountDetails';
//import updateServiceRequest from '@salesforce/apex/DirectDebitService.updateServiceRequest';
import validateIBANCallout from '@salesforce/apex/IBANValidatorController.validateIBANCallout'; // Anuroop 02-06-2025 : FIN-49 IBAN Validation - ADCB - Direct debit
import { CloseActionScreenEvent } from 'lightning/actions';
import { RefreshEvent } from "lightning/refresh";

export default class CreateNewDirectDebitRequestFromSalesOrder extends NavigationMixin(LightningElement)
{
    @api recordId;
    mapOfAccountDetailsByIDMap = [];
    customername = [];
    isLoading = false;
    ddrId;

    dd_CustomerBankAccountType = null;
    //dd_CustomerBankName             = '';
    dd_CustomerIBANNumber = '';

    dd_CustomerIdType = '';
    dd_CustomerIDNumber = '';
    dd_CustomerAccountName = '';
    dd_AccountId = '';
    dd_SalesOrderId = '';
    dd_DefaultPayerAccount = '';
    dd_PayerAccount;
    submitFromObject;
    isServiceRequest = false;
    //Start : Anuroop 02-06-2025 : FIN-49 IBAN Validation - ADCB - Direct debit
    isIBANValidated = false;
    showConfirmModal = false;
    isNameMatching = false;
    customerNameFromBank;
    restrict_DD_Request_On_IBAN_Validation = false;
    Restrict_IBAN_Verification;
    iban;
    alreadySubmitted = false;
    //End : Anuroop 02-06-2025 : FIN-49 IBAN Validation - ADCB - Direct debit



    connectedCallback() {
        this.restrict_DD_Request_On_IBAN_Validation = Restrict_DD_Request_On_IBAN_Validation.toLowerCase() === 'true';
        console.log('Restrict_DD_Request_On_IBAN_Validation : '+Restrict_DD_Request_On_IBAN_Validation);
        console.log('this.restrict_DD_Request_On_IBAN_Validation : '+this.restrict_DD_Request_On_IBAN_Validation);
        let salesOrderIdURL = this.recordId && this.recordId != null ? this.recordId : new URL(window.location.href).searchParams.get("recordId");
        let dVal = {};

        console.log('salesOrderIdURL---->>>' + salesOrderIdURL);

        if (salesOrderIdURL != null) {
            getSalesOrderAccountDetailsList({ salesOrderId: salesOrderIdURL })
                .then(result => {
                    console.log('Result from Apex---> ', JSON.stringify(result));
                    this.submitFromObject = result.submitFromObject;
                    let mapOfAccountDetailsByID = [];
                    let accountsWithRelationships = result.relationShips;

                    if (this.submitFromObject == 'HexaBPM__Service_Request__c') {
                        this.isServiceRequest = true;
                        this.dd_CustomerIdType = result.serviceRequest.BuyerName__r.IsPersonAccount == true ? 'UAE Emirates Identity Card' : 'Trade Licence Number';
                        this.dd_CustomerIDNumber = result.serviceRequest.BuyerName__r.RegistrationNumber__c;
                        this.dd_CustomerAccountName = result.serviceRequest.BuyerName__r.Name;
                        this.dd_AccountId = result.serviceRequest.BuyerName__c;
                        this.dd_SalesOrderId = result.salesOrderRecord.Id;
                        this.dd_PayerAccount = result.serviceRequest.BuyerName__c;
                        this.customername = [{ label: result.serviceRequest.BuyerName__r.Name, value: result.serviceRequest.BuyerName__c }];
                        this.dd_DefaultPayerAccount = result.serviceRequest.BuyerName__c;
                        mapOfAccountDetailsByID.push({ key: result.serviceRequest.BuyerName__c, value: result.serviceRequest.BuyerName__r });
                    } else {
                        this.dd_CustomerIdType = result.salesOrderRecord.Account__r.IsPersonAccount == true ? 'UAE Emirates Identity Card' : 'Trade Licence Number';
                        this.dd_CustomerIDNumber = result.salesOrderRecord.Account__r.IsPersonAccount == true ? result.salesOrderRecord.AccountNationalityIDNumber__c : result.salesOrderRecord.Account__r.RegistrationNumber__c;
                        this.dd_CustomerAccountName = result.salesOrderRecord.Account__r.Name;
                        this.dd_AccountId = result.salesOrderRecord.Account__c;
                        this.dd_SalesOrderId = result.salesOrderRecord.Id;
                        this.dd_PayerAccount = result.salesOrderRecord.Account__c;
                        this.customername = [{ label: result.salesOrderRecord.Account__r.Name, value: result.salesOrderRecord.Account__c }];
                        this.dd_DefaultPayerAccount = result.salesOrderRecord.Account__c;
                        mapOfAccountDetailsByID.push({ key: result.salesOrderRecord.Account__c, value: result.salesOrderRecord.Account__r });
                    }

                    this.dd_CustomerBankAccountType = null;
                    //this.dd_CustomerBankName = null;
                    this.dd_CustomerIBANNumber = '';

                    for (let i = 0; i < accountsWithRelationships.length; i++) {
                        this.customername = [... this.customername, { value: accountsWithRelationships[i].RelatedAccount__r.Id, label: accountsWithRelationships[i].RelatedAccount__r.Name, Id: accountsWithRelationships[i].Id, Relation: accountsWithRelationships[i].RelationshipType__c }];
                        mapOfAccountDetailsByID.push({ key: accountsWithRelationships[i].RelatedAccount__r.Id, value: accountsWithRelationships[i].RelatedAccount__r });
                    }

                    this.mapOfAccountDetailsByIDMap = mapOfAccountDetailsByID;
                    console.log('mapOfAccountDetailsByID--->>', JSON.stringify(this.mapOfAccountDetailsByIDMap));
                }).catch(error => {
                    this.error = error;
                    const evt = new ShowToastEvent({
                        title: 'Error',
                        message: 'Error while fetching data ' + error,
                        variant: 'error',
                        mode: 'sticky'
                    });
                    this.dispatchEvent(evt);
                });
        }
    }

    get AccountList() {
        return this.customername;
    }

    handleSubmit(event) {
        if(!this.alreadySubmitted){
            console.log('handle Submit');
            this.isLoading = true;
            //Start : Anuroop 02-06-2025 : FIN-49 IBAN Validation - ADCB - Direct debit
            if(!this.isIBANValidated){
                event.preventDefault();
                this.Restrict_IBAN_Verification = Restrict_IBAN_Verification.toLowerCase() === 'true';
                if (!this.Restrict_IBAN_Verification){ 
                    this.validateIBAN();
                    this.isLoading = false;
                }else{
                    this.template.querySelector('lightning-record-edit-form').submit();
                    this.alreadySubmitted = true;
                }
            }
            this.isLoading = false;
            //End : Anuroop 02-06-2025 : FIN-49 IBAN Validation - ADCB - Direct debit
        }
    }

    //Start : Anuroop 02-06-2025 : FIN-49 IBAN Validation - ADCB - Direct debit
    validateIBAN(event) {
        this.iban = null;
        this.isLoading = true;
        this.errorMessage = '';
        const ibanValue = this.template.querySelector('lightning-input-field[data-name="CustomerIBANNumber__c"]').value;
        this.iban = ibanValue;
        var pat = new RegExp('^[AE]{2}[0-9]{2}[0-9]{3}[0-9]{16}$');
        if(!pat.test(ibanValue)){
            const evt = new ShowToastEvent({
                title: 'Error',
                message: 'IBAN must start with ‘AE’ followed by 21 alphanumeric characters.',
                variant: 'error',
            });
            this.dispatchEvent(evt);
            this.isLoading = false;
            return false;
        }

        validateIBANCallout({
            iban: ibanValue
        }).then(result => {
            let tempResult = JSON.parse(JSON.stringify(result));
            if(tempResult.success) {
                this.customerNameFromBank = tempResult.IBANAccountTitle.trim();
                this.showCustomerNameFromBank = true;
                let customerNameFromSR = this.template.querySelector('lightning-input-field[data-name="CustomerAccountName__c"]').value.toLowerCase();
                let customerNameFromBank = this.customerNameFromBank;
                if(customerNameFromBank != null && customerNameFromBank != undefined && customerNameFromBank != '') {
                    customerNameFromBank = customerNameFromBank.split(" ")[0].replaceAll("*","").toLowerCase();
                    console.log('customerNameFromBank : '+customerNameFromBank);
                    console.log('customerNameFromSR : '+customerNameFromSR);
                    if(customerNameFromSR.indexOf(customerNameFromBank) != 0) {
                        this.isNameMatching = false;
                    }else{
                        this.isNameMatching = true;
                    }
                    this.openConfirmModal();
                    this.isLoading = false;
                }
            }else{
                const evt = new ShowToastEvent({
                    title: 'Error',
                    message: 'Invalid IBAN',
                    variant: 'error',
                });
                this.dispatchEvent(evt);
                this.isLoading = false;
            }
        }).catch(error => {
            this.isError = true;
            this.errorMessage = error;
            console.error('error>>>' + error);
            const evt = new ShowToastEvent({
                title: 'Error',
                message: error,
                variant: 'error',
            });
            this.dispatchEvent(evt);
            this.isLoading = false;
        });

    }

    confirmIBAN(event){
        if(!this.alreadySubmitted){
            this.isLoading = true;
            this.isIBANValidated = true;
            this.closeConfirmModal();        
            this.template.querySelector('lightning-record-edit-form').submit();
            this.alreadySubmitted = true;
        }
    }

    handleIBANChange(iban) {
        var pat = new RegExp('^[AE]{2}[0-9]{2}[0-9]{3}[0-9]{16}$');
        const evt = new ShowToastEvent({
            title: 'Error',
            message: 'IBAN must start with ‘AE’ followed by 21 alphanumeric characters.',
            variant: 'error',
        });
        this.dispatchEvent(evt);

        return pat.test(iban);
    }

    openConfirmModal(){
        this.showConfirmModal = true;
    }

    closeConfirmModal() {
        this.showConfirmModal = false;
    }
    //End : Anuroop 02-06-2025 : FIN-49 IBAN Validation - ADCB - Direct debit

    handleSuccess(event) {
        let recordId = event.detail.id;

       /*if (this.submitFromObject == 'HexaBPM__Service_Request__c') {
             let srId = this.recordId && this.recordId != null ? this.recordId : new URL(window.location.href).searchParams.get("recordId");
            console.log(srId);
            console.log(recordId);
            updateServiceRequest({ ddrId: recordId, recordId: srId })
                .then(result => {
                    this.handleNavigation(recordId);
                }).catch(err => {
                    const evt = new ShowToastEvent({
                        title: 'Error',
                        message: err.message.body,
                        variant: 'error'
                    });
                    this.dispatchEvent(evt);
                    this.handleNavigation(recordId);
                })
        } else {*/ 
            this.handleNavigation(recordId);
       //}
    }

    handleNavigation(recordId) {
        //console.log('handle Success', event.detail.id);
        this.isLoading = false;
        if (recordId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: recordId,
                    objectApiName: 'DirectDebitRequest__c',
                    actionName: 'view'

                }
            });
        } else {
            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: 'DirectDebitRequest__c',
                    actionName: 'home'

                }
            });
        }
    }

    handleError(event) {
        this.isLoading = false;

        console.log('Error - ', event.detail.detail);
        const evt = new ShowToastEvent({
            title: 'Error',
            message: event.detail.detail,
            variant: 'error',
            mode: 'sticky'
        });
        this.dispatchEvent(evt);

    }


    handlePayerAccountChange(event) {
        this.resetFormAction();
        let selectedPayerAccountId = event.detail.value;
        console.log('SelectedPayerAccount---' + selectedPayerAccountId);
        this.dd_PayerAccount = selectedPayerAccountId;
        let mapOfAccountDetailsByIDMap = this.mapOfAccountDetailsByIDMap;
        let dd_CustomerIDNumber = '';
        let dd_CustomerAccountName = '';
        let dd_CustomerIdType = '';

        this.dd_CustomerIdType = null;

        this.dd_CustomerBankAccountType = null;
        //this.dd_CustomerBankName = null;
        this.dd_CustomerIBANNumber = null;

        for (let i in mapOfAccountDetailsByIDMap) {
            if (mapOfAccountDetailsByIDMap[i]['key'] == selectedPayerAccountId) {
                dd_CustomerAccountName = mapOfAccountDetailsByIDMap[i]['value'].Name;
                dd_CustomerIdType = mapOfAccountDetailsByIDMap[i]['value'].IsPersonAccount ? 'UAE Emirates Identity Card' : 'Trade License Number';

                if (dd_CustomerIdType == 'Passport') {
                    this.dd_CustomerIDNumber = (this.mapOfAccountDetailsByIDMap[i]['value'].PassportNumber__pc != null && this.mapOfAccountDetailsByIDMap[i]['value'].PassportNumber__pc != '' && this.mapOfAccountDetailsByIDMap[i]['value'].PassportNumber__pc != undefined) ? this.mapOfAccountDetailsByIDMap[i]['value'].PassportNumber__pc : '';
                } else if (dd_CustomerIdType == 'UAE Emirates Identity Card') {
                    this.dd_CustomerIDNumber = (this.mapOfAccountDetailsByIDMap[i]['value'].NationalIdNumber__pc != null && this.mapOfAccountDetailsByIDMap[i]['value'].NationalIdNumber__pc != '' && this.mapOfAccountDetailsByIDMap[i]['value'].NationalIdNumber__pc != undefined) ? this.mapOfAccountDetailsByIDMap[i]['value'].NationalIdNumber__pc : '';
                } else if (dd_CustomerIdType == 'Trade License Number' && !this.mapOfAccountDetailsByIDMap[i]['value'].IsPersonAccount) {
                    this.dd_CustomerIDNumber = (this.mapOfAccountDetailsByIDMap[i]['value'].RegistrationNumber__c != null && this.mapOfAccountDetailsByIDMap[i]['value'].RegistrationNumber__c != '' && this.mapOfAccountDetailsByIDMap[i]['value'].RegistrationNumber__c != undefined) ? this.mapOfAccountDetailsByIDMap[i]['value'].RegistrationNumber__c : '';
                }
                //dd_CustomerIDNumber     = mapOfAccountDetailsByIDMap[i]['value'].NationalIdNumber__pc;

                break;
            }
        }

        //this.dd_CustomerIDNumber          = dd_CustomerIDNumber;
        this.dd_CustomerAccountName = dd_CustomerAccountName;
        this.dd_CustomerIdType = dd_CustomerIdType;

    }

    resetFormAction() {
        const inputFields = this.template.querySelectorAll(
            'lightning-input-field'
        );
        if (inputFields) {
            inputFields.forEach(element => {
                if (element.fieldName === "CustomerBankAccountType__c" || element.fieldName === "CustomerBankName__c" || element.fieldName === "CustomerIBANNumber__c") {
                    element.reset();
                }
            });
        }
    }


    handleCloseClick() {
        this.dispatchEvent(new RefreshEvent());
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    onCustIdTypeChange(event) {
        console.log('event.detail.value:::' + event.detail.value);
        console.log('dd_DefaultPayerAccount::' + this.dd_DefaultPayerAccount);

        this.dd_CustomerIdType = event.detail.value;
        let mapOfAccountDetailsByIDMap = this.mapOfAccountDetailsByIDMap;
        for (let i in mapOfAccountDetailsByIDMap) {
            if (mapOfAccountDetailsByIDMap[i]['key'] == this.dd_PayerAccount) {
                if (this.dd_CustomerIdType == 'Passport') {
                    this.dd_CustomerIDNumber = (this.mapOfAccountDetailsByIDMap[i]['value'].PassportNumber__pc != null && this.mapOfAccountDetailsByIDMap[i]['value'].PassportNumber__pc != '' && this.mapOfAccountDetailsByIDMap[i]['value'].PassportNumber__pc != undefined) ? this.mapOfAccountDetailsByIDMap[i]['value'].PassportNumber__pc : '';
                } else if (this.dd_CustomerIdType == 'UAE Emirates Identity Card') {
                    this.dd_CustomerIDNumber = (this.mapOfAccountDetailsByIDMap[i]['value'].NationalIdNumber__pc != null && this.mapOfAccountDetailsByIDMap[i]['value'].NationalIdNumber__pc != '' && this.mapOfAccountDetailsByIDMap[i]['value'].NationalIdNumber__pc != undefined) ? this.mapOfAccountDetailsByIDMap[i]['value'].NationalIdNumber__pc : '';
                } else if (this.dd_CustomerIdType == 'Trade Licence Number' && !this.mapOfAccountDetailsByIDMap[i]['value'].IsPersonAccount) {
                    this.dd_CustomerIDNumber = (this.mapOfAccountDetailsByIDMap[i]['value'].RegistrationNumber__c != null && this.mapOfAccountDetailsByIDMap[i]['value'].RegistrationNumber__c != '' && this.mapOfAccountDetailsByIDMap[i]['value'].RegistrationNumber__c != undefined) ? this.mapOfAccountDetailsByIDMap[i]['value'].RegistrationNumber__c : '';
                }
            }
        }

    }

    get isBlockProcess(){
        return this.restrict_DD_Request_On_IBAN_Validation && !this.isNameMatching;
    }
}