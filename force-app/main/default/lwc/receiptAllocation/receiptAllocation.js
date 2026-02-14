import { api, LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getReceiptAllocationbyReceiptId from '@salesforce/apex/ReceiptAllocationController.getReceiptAllocationbyReceiptId';
import getRelatedSalesOrderbyAccountId from '@salesforce/apex/ReceiptAllocationController.getRelatedSalesOrderbyAccountId';
import getInvoicesApplicableForSO from '@salesforce/apex/ReceiptAllocationController.getInvoicesApplicableForSO';
import saveReceiptAllocation from '@salesforce/apex/ReceiptAllocationController.saveReceiptAllocation';
import canUserModifyReceipt from '@salesforce/apex/ReceiptAllocationController.canUserModifyReceipt'; //FIN-68 changes by Sai Kumar

const COLUMN = [
    { title: 'Account', fieldName: 'account', type: 'picklist-text', style: 'overflow: initial;' },
    { title: 'Unit Number', fieldName: 'unitNumber', type: 'picklist-text', style: 'overflow: initial;' },
    { title: 'Sales Order #', fieldName: 'salesOrder', type: 'text', readonly: true },
    { title: 'Installment # / Other Charges', fieldName: 'installmentNoOtherCharge', type: 'picklist-text', style: 'overflow: initial;' },
    { title: 'Type', fieldName: 'chargeType', type: 'text', readonly: true },
    { title: 'Total Invoice Amount', fieldName: 'totalInvoiceAmount', type: 'currency', readonly: true },
    { title: 'Current Outstanding Amount', fieldName: 'currentOutstandingAmount', type: 'currency', readonly: true },
    { title: 'Currently Amount Applied', fieldName: 'currentAmountApplied', type: 'currency', readonly: true },
    { title: 'Amount Applied', fieldName: 'amountApplied', type: 'currency' },
    { title: 'Final Outstanding Amount', fieldName: 'finalOutstandingAmount', type: 'currency', readonly: true },
    { title: '', fieldName: 'delete', type: 'button' }
];

import { reduceErrors } from 'c/ldsUtils';

export default class ReceiptAllocation extends NavigationMixin(LightningElement) {
    @api recordId;
    @track recId = '';
    @track columns = COLUMN;
    @track accountOptions = [];
    @track salesOrderOptions = {};
    @track lineOptions = {};
    @track isLoading = false;
    @track showButtons = true; //FIN-68 changes by Sai Kumar

    @track receiptData = {};
    @track totalAmountApplied = 0;
    @track receiptAllocationList = [];
    @track disableSave = true;
    @track refresh = '';

    async connectedCallback() {
        this.refresh = Math.floor((Math.random() * 1000000)) + '';
        this.recId = this.recordId ? this.recordId : new URL(window.location.href).searchParams.get("recordId");
        let isOpen = new URL(window.location.href).searchParams.get("c__isOpen");
        // Check user permissions
        await this.checkUserPermissions(); //FIN-68 changes by Sai Kumar
        if (!isOpen) {
            this.openReceiptAllocation();
            await this.getReceiptData();
            this.refresh = Math.floor((Math.random() * 1000000)) + '';
        } else {
            this.recId = new URL(window.location.href).searchParams.get("c__rId");
            await this.getReceiptData();
            this.refresh = Math.floor((Math.random() * 1000000)) + '';
        }
        console.log('recordId>>>' + this.recId);
    }

    //FIN-68: Manages visibility of receipt allocation action buttons based on user permissions by Sai Kumar
    async checkUserPermissions() {
        try {
            this.showButtons = await canUserModifyReceipt({ receiptId: this.recId });
        } catch (error) {
            console.error('Error checking permissions:', error);
            // Default to showing buttons to maintain existing functionality
            this.showButtons = true;
        }
    }

    renderedCallback() {
        let recordId = new URL(window.location.href).searchParams.get("c__rId");
        if (recordId != undefined && recordId != null && recordId != '' && recordId != this.recId) {
            this.recId = recordId;
            this.getReceiptData();
        }
        //FIN-68 changes by Sai Kumar // Always check permissions if recId is set
        if (this.recId) {
            this.checkUserPermissions();  
        }
    }

    async getReceiptData() {
        this.isLoading = true;
        this.receiptData = {};
        this.receiptAllocationList = [];
        console.log('getReceiptData');
        await getReceiptAllocationbyReceiptId({
            receiptId: this.recId
        }).then(result => {
            let tempResult = JSON.parse(result);
            console.log('result>>>', tempResult);
            this.receiptData = JSON.parse(JSON.stringify(tempResult));
            this.receiptAllocationList = JSON.parse(JSON.stringify(tempResult.rceiptAllocationList));

            this.totalAmountApplied = 0;
            for (let allocation of this.receiptAllocationList) {
                this.totalAmountApplied += allocation.amountApplied;
            }

            this.accountOptions = [...this.accountOptions];
            let tempMap = {};
            let tempRelatedAccounts = [];
            for (let acc of tempResult.relatedAccounts) {
                if (tempMap.hasOwnProperty(acc.value)) {
                    tempMap[acc.value] = tempMap[acc.value] + 1;
                    acc.value = acc.value + '_' + tempMap[acc.value];
                    tempRelatedAccounts.push(acc);
                } else {
                    tempMap[acc.value] = 1;
                    acc.value = acc.value + '_' + tempMap[acc.value];
                    tempRelatedAccounts.push(acc);
                }
            }
            this.accountOptions = tempRelatedAccounts;
            this.refresh = Math.floor((Math.random() * 1000000)) + '';
            this.isLoading = false;
        }).catch(error => {
            console.error('error>>>' + error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    variant: 'error',
                    message: error,
                })
            );
            this.isLoading = false;
        })
    }

    openReceiptAllocation() {
        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'Receipt_Allocation',
            },
            state: {
                'c__rId': this.recId,
                'c__isOpen': true
            }
        });
    }

    checkValidation(isSave, checkSame) {
        console.log('validation::');
        let isError = false;
        let errorMessage = '';

        let uniqueList = [];
        this.totalAmountApplied = 0;
        for (let allocation of this.receiptAllocationList) {
            this.totalAmountApplied += allocation.amountApplied;
            if (checkSame) {
                let unique = allocation.account + '_' + allocation.unitNumber + '_'+allocation.salesOrder +'_'+ allocation.installmentOtherChargeId;
                if (uniqueList.length > 0 && uniqueList.includes(unique)) {
                    isError = true;
                    errorMessage = 'Please do not select the same Installment number or other changes. Kindly use the existing one.'
                    break;
                } else {
                    uniqueList.push(unique);
                }
            } 
            if (checkSame && !isSave) {
                continue;
            }

            if (this.receiptData.amount < this.totalAmountApplied) {
                isError = true;
                errorMessage = "Sum of Receipt Allocation's Amount Applied cannot exceed from Receipt Amount.";
                break;
            } else if (allocation.Id != '' && allocation.totalInvoiceAmount < allocation.amountApplied) {
                isError = true;
                errorMessage = "Receipt Allocation's Amount Applied cannot be exceed from Total Invoice Amount.";
                break;
            } else if (allocation.Id == '' && allocation.currentOutstandingAmount < allocation.amountApplied) {
                isError = true;
                errorMessage = "Receipt Allocation's Amount Applied cannot be exceed from Current Outstanding Amount.";
                break;
            }

            if (isSave) {
            console.log('allocation.account' + allocation.account);
            console.log('allocation.unitNumber' + allocation.unitNumber);
            console.log('allocation.account' + allocation.installmentNoOtherCharge);
            

                if (!allocation.account || !allocation.unitNumber || !allocation.installmentNoOtherCharge) {
                    isError = true;
                    errorMessage = "Account, Unit Number and Installment # / Other Charges cannot be blank.";
                    break;
                } else if (allocation.amountApplied < 0) {
                    isError = true;
                    errorMessage = "Amount Applied cannot be less than 0";
                    break;
                }

                if (!isError && allocation.amountApplied.toString().includes('.') && allocation.amountApplied.toString().split('.')[1].length > 2) {
                    isError = true;
                    errorMessage = "Please make sure you have added less than 2 digit fraction digit in amount.";
                    break;
                }
            }
        }
        // if (!isError && isSave) {
        //     if (this.totalAmountApplied != this.receiptData.amount) {
        //         isError = true;
        //         errorMessage = 'Please allocate entire "' + this.receiptData.amount +  '" amount.';
        //     }
        // }

        if (isError) {
            console.log('error>>>' + errorMessage);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    variant: 'error',
                    message: errorMessage,
                })
            );
        }
        return isError;
    }

    async handleChange(event) {
        console.log('name>>>' + event.detail.recordIndex);
        console.log('fieldName>>>' + event.detail.fieldName);
        console.log('value>>>' + event.detail.value);
        console.log('label>>>' + event.detail.label);

        let recordIndex = event.detail.recordIndex;
        let fieldName = event.detail.fieldName;
        let value = event.detail.value;
        this.receiptAllocationList = [...this.receiptAllocationList];
        if (fieldName == 'amountApplied') {
            this.disableSave = false;
            this.receiptAllocationList[recordIndex][fieldName] = parseFloat(value);
            this.receiptAllocationList[recordIndex].finalOutstandingAmount = this.receiptAllocationList[recordIndex].currentOutstandingAmount + this.receiptAllocationList[recordIndex].currentAmountApplied - parseFloat(value);
            this.checkValidation(false, false);
        } else if (fieldName == 'account') {
            this.receiptAllocationList[recordIndex][fieldName] = value;
            for (let acc of this.accountOptions) {
                if (acc.value == value) {
                    this.receiptAllocationList[recordIndex]['accountId'] = acc.accountId;


                    this.receiptAllocationList[recordIndex]['unitNumber'] = '';
                    this.receiptAllocationList[recordIndex]['salesOrderId'] = '';
                    this.receiptAllocationList[recordIndex]['salesOrder'] = '';
                    this.receiptAllocationList[recordIndex]['installmentNoOtherCharge'] = '';
                    this.receiptAllocationList[recordIndex]['isInstallment'] = false;
                    this.receiptAllocationList[recordIndex]['installmentOtherChargeId'] = '';
                    this.receiptAllocationList[recordIndex]['chargeType'] = '';
                    this.receiptAllocationList[recordIndex]['totalInvoiceAmount'] = 0;
                    this.receiptAllocationList[recordIndex]['currentOutstandingAmount'] = 0;
                    this.receiptAllocationList[recordIndex]['currentAmountApplied'] = 0;
                    this.receiptAllocationList[recordIndex]['installmentNoOtherCharge'] = 0;
                    this.receiptAllocationList[recordIndex]['finalOutstandingAmount'] = 0;
                    break;
                }
            }
            await this.getSalesOrder(this.receiptAllocationList[recordIndex]['accountId']);
        } else if (fieldName == 'unitNumber') {
            console.log('receiptAllocationList ',this.receiptAllocationList);
            console.log('this.salesOrderOptions ',this.salesOrderOptions);
            /*for (let salesOrder of this.salesOrderOptions[this.receiptAllocationList[recordIndex].accountId]) {
                console.log('salesOrder',salesOrder);
                if (salesOrder.salesOrderId == value) {
                    value = salesOrder.label;
                    break;
                }
            }*/
            this.receiptAllocationList[recordIndex][fieldName] = event.detail.value;

            for (let salesOrder of this.salesOrderOptions[this.receiptAllocationList[recordIndex].accountId]) {
                console.log('salesOrder',salesOrder);
                if (salesOrder.salesOrderId == value) {
                    this.receiptAllocationList[recordIndex]['salesOrderId'] = salesOrder.salesOrderId;
                    this.receiptAllocationList[recordIndex]['salesOrder'] = salesOrder.salesOrderName;
                   // this.receiptAllocationList[recordIndex]['unitNumber'] = salesOrder.label; 
                    this.receiptAllocationList[recordIndex]['installmentNoOtherCharge'] = '';
                    this.receiptAllocationList[recordIndex]['isInstallment'] = false;
                    this.receiptAllocationList[recordIndex]['installmentOtherChargeId'] = '';
                    this.receiptAllocationList[recordIndex]['chargeType'] = '';
                    this.receiptAllocationList[recordIndex]['totalInvoiceAmount'] = 0;
                    this.receiptAllocationList[recordIndex]['currentOutstandingAmount'] = 0;
                    this.receiptAllocationList[recordIndex]['currentAmountApplied'] = 0;
                    this.receiptAllocationList[recordIndex]['amountApplied'] = 0;
                    this.receiptAllocationList[recordIndex]['finalOutstandingAmount'] = 0;
                    break;
                }
            }
            console.log('this.receiptAllocationList[recordIndex][fieldName]',this.receiptAllocationList[recordIndex][fieldName]);
            
            await this.getLines(this.receiptAllocationList[recordIndex]['accountId'], this.receiptAllocationList[recordIndex]['salesOrderId']);
            
            this.receiptAllocationList = [...this.receiptAllocationList];
            this.receiptAllocationList = JSON.parse(JSON.stringify(this.receiptAllocationList));
            //this.receiptAllocationList = JSON.parse(JSON.stringify(this.receiptAllocationList));
        } else if (fieldName == 'installmentNoOtherCharge') {
            this.receiptAllocationList[recordIndex][fieldName] = value;
            let isSame = this.checkValidation(false, true);
            for (let line of this.lineOptions[this.receiptAllocationList[recordIndex].accountId + '_' + this.receiptAllocationList[recordIndex].salesOrderId]) {
                if (!isSame && line.value == value) {
                    this.receiptAllocationList[recordIndex]['isInstallment'] = line.chargeType == 'Installment' ? true : false;
                    this.receiptAllocationList[recordIndex]['installmentOtherChargeId'] = line.installmentOtherChargeId;
                    this.receiptAllocationList[recordIndex]['chargeType'] = line.chargeType;
                    this.receiptAllocationList[recordIndex]['totalInvoiceAmount'] = line.totalInvoiceAmount;
                    this.receiptAllocationList[recordIndex]['currentOutstandingAmount'] = line.currentOutstandingAmount;
                    this.receiptAllocationList[recordIndex]['currentAmountApplied'] = 0;
                    this.receiptAllocationList[recordIndex]['amountApplied'] = 0;
                    this.receiptAllocationList[recordIndex]['finalOutstandingAmount'] = line.finalOutstandingAmount;
                    break;
                }
            }
        }
        console.log('receiptAllocationList>>>' + JSON.stringify(this.receiptAllocationList));
    }

    async getSalesOrder(accId) {
        this.isLoading = true;
        await getRelatedSalesOrderbyAccountId({
            accountId: accId
        }).then(result => {
            let tempResult = JSON.parse(result);
            console.log('result>>>>>>>>', tempResult);

            this.salesOrderOptions[accId] = tempResult;
            console.log('this.salesOrderOptions',this.salesOrderOptions);
            this.salesOrderOptions[accId].forEach(element => {
                element.value = element.salesOrderId;
            });
            this.salesOrderOptions = JSON.parse(JSON.stringify(this.salesOrderOptions));
            console.log('this.salesOrderOptions after',this.salesOrderOptions);
            this.isLoading = false;
        }).catch(error => {
            console.error('error>>>', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    variant: 'error',
                    message: error,
                })
            );
            this.isLoading = false;
        })
    }

    async getLines(accId, salesOrderId) {
        console.log('getLines',accId,salesOrderId);
        this.isLoading = true;
        await getInvoicesApplicableForSO({
            SalesOrderId: salesOrderId
        }).then(result => {
            let tempResult = JSON.parse(result);
            for (let opt of tempResult) {
                opt.label = opt.installmentNoOtherCharge;
                opt.value = opt.installmentNoOtherCharge;
               
            }
            console.log('result>>>', tempResult);

            this.lineOptions[accId + '_' + salesOrderId] = tempResult;
            // for (let line in this.lineOptions) {
            //     this.lineOptions[line] = [...this.lineOptions[line]];
            // }

            this.isLoading = false;
        }).catch(error => {
            console.error('error>>>', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    variant: 'error',
                    message: error,
                })
            );
            this.isLoading = false;
        })
    }

    addAllocation(event) {
        this.disableSave = false;
        let newRow = {
            Id: '',
            account: '',
            accountId: '',
            salesOrder: '',
            salesOrderId: '',
            unitNumber: '',
            installmentNoOtherCharge: '',
            installmentOtherChargeId: '',
            isInstallment: true,
            chargeType: '',
            totalInvoiceAmount: 0,
            currentOutstandingAmount: 0,
            currentAmountApplied: 0,
            amountApplied: 0,
            finalOutstandingAmount: 0
        }
        this.receiptAllocationList.push(newRow);
    }

    deleteAllocation(event) {
        let rowIndex = event.detail.recordIndex
        if (confirm('Are you sure you want to delete?')) {
            this.receiptAllocationList.splice(rowIndex, 1);
        }
    }

    async handleSave(event) {
        console.log('handleSave');

        let isError = this.checkValidation(true, true);

        if (!isError) {
            this.isLoading = true;
            let allocation = JSON.stringify(this.receiptAllocationList);
            await saveReceiptAllocation({
                receiptAllocations: allocation,
                receiptId: this.recId
            }).then(result => {
                this.getReceiptData();
                this.isLoading = false;
                this.backToReceiptAcknowledgement();
            }).catch(error => {
                console.error('error>>>', error, reduceErrors(error));
                let errormessage = '';
                let errors = reduceErrors(error);
                if (errors && errors.length && errors.length > 0) {
                    errors.forEach(element => {
                        errormessage = errormessage + element + ', ';
                    });
                    errormessage = errormessage.slice(0, -1);
                }
                //SERVICE-233
                if(errormessage.includes('FIELD_CUSTOM_VALIDATION_EXCEPTION') && !errormessage.includes('CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY')){
                    errormessage = errormessage.split(',')[1];
                }
                if(errormessage.includes('FIELD_CUSTOM_VALIDATION_EXCEPTION') && errormessage.includes('CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY')){
                    errormessage = errormessage.split(',')[2];
                    errormessage = errormessage.split('[]')[0];
                }

                /*errormessage = errormessage.substring(
                    errormessage.indexOf("FIELD_CUSTOM_VALIDATION_EXCEPTION,") + 1, 
                    errormessage.lastIndexOf("[]") - 1
                );*/
               
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        variant: 'error',
                        message: errormessage,
                    })
                );
                this.isLoading = false;
            })
        }
    }

    backToReceiptAcknowledgement() {
        //let redirectionPageUrl;
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recId,
                objectApiName: 'ReceiptAcknowledgement__c',
                actionName: 'view'
            }
        }).then(url => {
            console.log('url' + url);
            this.redirectionPageUrl = url;
        });
        setTimeout(() => {
            window.location.href = this.redirectionPageUrl;
        }, 300);
    }

    get remainingAmount() {
        return this.receiptData && this.receiptData.amount != null ? this.receiptData.amount - this.totalAmountApplied : 0;
    }
}