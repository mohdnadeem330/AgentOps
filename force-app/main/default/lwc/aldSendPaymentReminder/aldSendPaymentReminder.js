import { LightningElement,api, wire, track } from 'lwc';
import sendPaymentReminder from '@salesforce/apex/ALD_IL_PaymentReminder.sendReminder';
import sendPaymentReminderSendGrid from '@salesforce/apex/ALD_IL_PaymentReminder.sendReminderEmailViaSendGrid';
import { currentPageRef } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import SALESORDER_ID from '@salesforce/schema/SalesOrder__c';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

const fields = [SALESORDER_ID];

export default class AldSendPaymentReminder extends LightningElement {
    @api recordId;// = 'a1g8d000000dAXPAA2';
    askConfirmation = false;
    inputObj = {};
    showSpinner = false;
    salesOrderId;

    disableSendReminderButton = true;
    @track selectedReminderType = '';
    @track reminderTypeOptions = [
        { label: 'First Payment Reminder', value: 'first' },
        { label: 'Second Payment Reminder', value: 'second' },
        { label: 'Third Payment Reminder', value: 'third' },
    ];

    handleReminderTypeChange(event) {
        
        this.selectedReminderType = event.detail.value;

        if(this.selectedReminderType){
            this.disableSendReminderButton = false;
        }
    }

    handleSendReminder() {
        this.showSpinner = true;
        setTimeout(() => {
            sendPaymentReminderSendGrid({ilId:this.recordId, reminderType: this.selectedReminderType, salesOrderId:this.salesOrderId})
            .then(result => {
                this.handleToastMessage(result, result.includes('Success') ? 'success' : 'error');
                this.handleCloseModal();
            })
            .catch(error => {
                this.showSpinner = false;
                this.handleToastMessage(error, 'error');
            });
        }, 200);
    }
    
    @wire(getRecord, { recordId: '$recordId', fields }) record({ error, data }){
        if (data) {
            this.salesOrderId = getFieldValue(data, SALESORDER_ID);
            console.log('###salesOrderId###' + this.salesOrderId);
        }
    }

    connectedCallback() {
        
        let inputObj = {};
        inputObj.header = 'Send Payment Reminder Email';
        inputObj.ProcessOne = 'Mile stone change letter';
        inputObj.ProcessTwo = 'Payment Reminder';
        inputObj.ProcessOneLabel = 'Send Milestone Change Letter';
        inputObj.ProcessTwoLabel = 'Send Payment Reminder';
        inputObj.cancelBtnLabel = 'Cancel';
        this.inputObj = inputObj;
        setTimeout(() => {
            //recordId is not loading immediately while calling from Quick Action, So added timeout for that // SARAN
            this.askConfirmation = true;
            
        }, 200);
    }
    handleReminderProcess(event) {
        console.log(event.target.title);
        this.sendReminder(event.target.title);
    }

    sendReminder(process) {
        this.showSpinner = true;
        setTimeout(() => {
            sendPaymentReminder({ilId:this.recordId,process:process,salesOrderId:this.salesOrderId})
            .then(result => {
                this.handleToastMessage(result, result.includes('Success') ? 'success' : 'error');
                this.handleCloseModal();
            })
            .catch(error => {
                this.showSpinner = false;
                this.handleToastMessage(error, 'error');
            });
        }, 200);
    }

    handleCloseModal() {
        this.askConfirmation = false;
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleToastMessage(msg, status) {
        const evt = new ShowToastEvent({
            title: msg,
            message: '',
            variant: status,
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }
}