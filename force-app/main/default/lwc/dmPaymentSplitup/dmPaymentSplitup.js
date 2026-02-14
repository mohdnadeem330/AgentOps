import { LightningElement, api, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import getCaseInfo from '@salesforce/apex/dmPaymentSplitupHandler.getCaseInfo';
import createPaymentReqs from '@salesforce/apex/dmPaymentSplitupHandler.createPaymentReqs';

export default class DmPaymentSplitup extends LightningElement {
    @api recordId;
    showSpinner = false;
    @track paymentLines = [];
    readMode = false;
    validInfo = false;
    @track servicePrice;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId || this.recordId;
        }
    }
    connectedCallback() {
        this.getCaseDetails();
    }
    get paymentOptions(){
         return [
            { label: 'CDC', value: 'CDC' },
            { label: 'PDC', value: 'PDC' },
            { label: 'Wire Transfer', value: 'Wire Transfer' },
            
        ];
    }
    getCaseDetails() {
        getCaseInfo({ recId: this.recordId })
            .then(data => {
                if (data) {
                    if (data.Request_split_payment__c == 'Yes' && data.Number_Of_Installments__c !== undefined) {
                        this.validInfo = true;
                        if (data.Payment_Requests__r) {
                            this.paymentLines = data.Payment_Requests__r;
                            this.servicePrice = data.Total_Amount__c;
                            this.readMode = true;
                        } else
                            this.preparePaymentInfo(data.Number_Of_Installments__c, data.Total_Amount__c);
                    } else {
                        this.validInfo = false;
                    }
                }
            }).catch(error => {
                //console.log(JSON.stringify(error));
            });
    }

    preparePaymentInfo(noOfSplit, amount) {
        this.servicePrice = amount;
        let currentDate = new Date();
        currentDate.setDate(new Date(currentDate).getDate());
        let formattedDate = currentDate.toISOString().split('T')[0];

        for (let i = 0; i < Number(noOfSplit); i++) {
            /*let payment = new Object();
            payment.SObjectType = 'Payment_Request__c';
            payment.Case__c = this.recordId;
            payment.Amount__c = (amount / noOfSplit).toFixed(2);
            payment.Instalment_Date__c = formattedDate;
            payment.Instalment_Percentage__c = (100 / noOfSplit).toFixed(2);
            payment.Instalment_No__c = i + 1;
            payment.Payment_Type__c = 'PDC';*/
            let payment = new Object();
            payment.SObjectType = 'Payment_Request__c';
            payment.Case__c = this.recordId;
            payment.Amount_without_VAT__c = (amount / noOfSplit).toFixed(2);
            payment.VAT_Amount__c = (payment.Amount_without_VAT__c * 0.05).toFixed(2);
            payment.Amount__c = (parseFloat(payment.Amount_without_VAT__c) + parseFloat(payment.VAT_Amount__c)).toFixed(2);
            payment.Instalment_Date__c = formattedDate;
            payment.Instalment_Percentage__c = (100 / noOfSplit).toFixed(2);
            payment.Instalment_No__c = i + 1;
            payment.Payment_Type__c = 'PDC';

            this.paymentLines.push(payment);
        }

    }
    inputChange(event) {
        try {
            let index = event.target.dataset.index;
            let name = event.target.name;
            let val = event.target.value;
            if (name == 'Instalment_Percentage__c') {
                this.paymentLines[index].Amount__c = ((this.servicePrice * Number(val)) / 100).toFixed(2);
            }
            if (name == 'Amount__c') {
                this.paymentLines[index].Instalment_Percentage__c = (val * 100 / this.servicePrice);
            }
            this.paymentLines[index][name] = val;
        } catch (e) {
            //console.log(e.message);
        }

    }
    handleEdit() {
        this.readMode = false;
    }
    handleSave() {      
        let totalPercentage = 0;
        this.paymentLines.forEach(item => {         
            totalPercentage += Number(item.Instalment_Percentage__c);
        });
        
        if (100 != totalPercentage) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'warning',
                    message: 'Total percentage should be 100.',
                    variant: 'warning'
                })
            );
        } else {
            this.showSpinner = true;
            createPaymentReqs({ payments: this.paymentLines })
                .then(data => {
                    this.getCaseDetails();
                    this.showSpinner = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'success',
                            message: 'Payment installment has been updated successfully.',
                            variant: 'success'
                        })
                    );

                    this.readMode = true;
                }).catch(error => {
                    this.showSpinner = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'error',
                            message: 'Unable to process your request, please check with admin.',
                            variant: 'error'
                        })
                    );
                });
        } 

    }


}