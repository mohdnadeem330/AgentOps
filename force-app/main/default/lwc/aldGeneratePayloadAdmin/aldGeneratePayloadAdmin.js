import { LightningElement } from 'lwc';
import generateCustomerRequest from '@salesforce/apex/ALD_RequestGenerator.generateCustomerRequest';
import generateSalesOrderRequest from '@salesforce/apex/ALD_RequestGenerator.generateSalesOrderRequest';
import generateReceiptRequest from '@salesforce/apex/ALD_RequestGenerator.generateReceiptRequest';

export default class AldGeneratePayloadAdmin extends LightningElement {
/**
 * Purpose of this component is to generate the payload to verify all good from Development side
 * Author: Saravanan Sekar : ssekar@aldar.com : 15-12-2022
 */
    payLoad;
    payloadFor;
    error;
    recId;
    payLoadForOptions = [{label:'CUSTOMER_RECEIPT',value:'CUSTOMER_RECEIPT'},{label:'SALES_ORDER',value:'SALES_ORDER'},{label:'RECEIPTS',value:'RECEIPTS'}];
    connectedCallback() {
        console.log('Component Loaded');
    }

    handlePayloadForChange(event) {
        this.payloadFor = event.target.value;
    }
    handleIdChanges(event) {
        this.recId = event.target.value;
    }

    handleGetPayload() {
        let recId = this.recId;
        let payloadFor = this.payloadFor;
        if(recId!=null && recId.length==18 && payloadFor!='') {
            if(payloadFor == 'CUSTOMER_RECEIPT') {
                this.generateCustomerPayload();
            } else if(payloadFor == 'SALES_ORDER') {
                this.generateSalesOrderPayload();
            } else if(payloadFor == 'RECEIPTS') {
                this.generateReceiptPayload();
            }
        } else {
            alert('Please input valid values!');
        }
        
    }

    generateCustomerPayload() {
        let recIds = [];
        recIds.push(this.recId);
        generateCustomerRequest({accIds:recIds})
        .then(result => {
            this.payLoad = JSON.stringify(JSON.parse(result), null, 4);
            console.log('result -> ',result);
        })
        .catch(error => {
            this.error = error;
            console.log('error -> ',error);
        });
    }

    generateSalesOrderPayload() {
        let recIds = [];
        recIds.push(this.recId);
        generateSalesOrderRequest({soIds:recIds})
        .then(result => {
            this.payLoad = JSON.stringify(JSON.parse(result), null, 4);
            console.log('result -> ',result);
        })
        .catch(error => {
            this.error = error;
            console.log('error -> ',error);
        });
    }

    generateReceiptPayload() {
        let recIds = [];
        recIds.push(this.recId);
        generateReceiptRequest({pcIds:recIds})
        .then(result => {
            this.payLoad = JSON.stringify(JSON.parse(result), null, 4);
            console.log('result -> ',JSON.parse(result));
        })
        .catch(error => {
            this.error = error;
            console.log('error -> ',error);
        });
    }
}