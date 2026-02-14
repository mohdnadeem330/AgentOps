import { LightningElement, api, wire } from 'lwc';
import fetchOCFields from '@salesforce/apex/ALDOC_OtherChargesHelper.fetchOCFields';
import handleSalesOrder from '@salesforce/apex/ALDOC_OtherChargesHelper.fetchSalesOrder';
import handleInsert from '@salesforce/apex/ALDOC_OtherChargesHelper.insertSalesOrderOtherCharge';
import checkIsFinanceHeadGroup from '@salesforce/apex/ALDOC_OtherChargesHelper.checkIsFinanceHeadGroup';
import VAT_ELIGIBLE_TYPES from '@salesforce/label/c.Vat_Calculation_For_Type_Of_Charge';
import LightningConfirm from 'lightning/confirm';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';

const CONST_AMOUNT='Amount__c';
const CONST_AMOUNT_WITHOUT_VAT='AmountWithoutVAT__c';
const CONST_AMOUNT_RECEIVED='AmountReceived__c';
const CONST_OUTSTANDING_AMOUNT='OutstandingAmount__c';
const CONST_OUTSTANDING_AMOUNT_IN_WORDS='OutstandingAmountinwords__c';
const CONST_VAT_AMOUNT='VATAmount__c';
const CONST_TYPE_OF_CHARGE_LABEL='Type Of Charge';
const CONST_TYPE_OF_CHARGE='TypeOfCharge__c';
const CONST_SUB_TYPE_OF_CHARGE='SubType__c';
const CONST_ACCOUNT='Account__c';
const CONST_SALES_ORDER_ID='SalesOrder__c';
const CONST_PAYMENT_METHOD='Payment_Method__c';
const CONST_WIRE_TRANSFER='Wire Transfer';
const CONST_CUSTOMER_REFUND='Customer Refund';
const CONST_DEBIT_MEMO='Debit Memo';

export default class AldNewOtherCharges extends NavigationMixin(LightningElement) {

    @api recordId; //Other charges record id
    @api objectName = 'SalesOrderOtherCharges__c';
    @api fieldSetName = 'New_OC_For_Finance';
    @api fieldSetName_Bank_Info = 'Bank_info';
    soRecId; //Sales order record id

    allFields = [];
    allBankFields = [];//To capture the bank fields
    errorOnCallback;
    errorMessage;
    VATAmount_c;
    TypeOfCharge_c;
    isAmountPresent = false;

    vatPercentage = 5;
    vatAmount = 0;
    actualAmount;
    totalAmount;
    salesOrderData = {};

    typeOfChargeLabel = 'Type Of Charge';
    subTypeOfChargeLabel = 'Sub Type Of Charge';
    disableSubType = true;

    /*Show Hide Attributes - START */
    isSpinner = false;
    showRefundSection = false;
    activeSectionName = ['A'];
    isValidUser = false;
    /*Show Hide Attributes - END */

    /*get typeOfChargeOptions() {
        return [
            { label: 'ADM Fee', value: 'ADM Fee' },
            { label: 'ADM Admin Fee', value: 'ADM Admin Fee' },
            { label: CONST_CUSTOMER_REFUND, value: CONST_CUSTOMER_REFUND },
            { label: 'Late Payment Charges', value: 'Late Payment Charges' },
            { label: 'Legal Fee', value: 'Legal Fee'},
            { label: 'Transfer Fee Charge', value: 'Transfer Fee Charge' }
        ];
    }*/

    get typeOfChargeOptions() {
        return [
            { label: CONST_CUSTOMER_REFUND, value: CONST_CUSTOMER_REFUND },
            { label: 'Legal Fee', value: 'Legal Fee'},
            { label: 'Late Payment Charges', value: 'Late Payment Charges' },
            { label: 'RTO OPTION FEE', value: 'RTO OPTION FEE' },
            { label: 'ADM Fee', value: 'ADM Fee' },
            { label: 'DLD', value: 'DLD' },
            { label: 'RAK Municipality Fee', value: 'RAK Municipality Fee' },
            { label: 'Evaluation Fee', value: 'Evaluation Fee' },
            { label: 'SPA Charges', value: 'SPA Charges' },
            { label: 'Commission Fees (For Off-Plan Property Transfer)', value: 'Commission Fees (For Off-Plan Property Transfer)' },
            { label: 'Other Miscellaneous Charges', value: 'Other Miscellaneous Charges' }
           
        ];
    }

    /*{ label: 'Last Installment Rebate', value: 'Last Installment Rebate'} */

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        const urlValue = currentPageReference.state.c__phParameter;
            console.log('urlValue ',urlValue);
            this.urlLanguage = currentPageReference.state?.lang;
            this.urlType = currentPageReference.state?.type;
    }

    async checkIsValidUser() {
        this.isSpinner = true;
        this.IsValidUserForOC = await checkIsFinanceHeadGroup();
        return this.IsValidUserForOC == 'Success';
    }
    async connectedCallback() {
        this.soRecId = new URL(window.location.href).searchParams.get("c__rId");
        
        if(await this.checkIsValidUser()) {
            this.isValidUser = true;
            
            await fetchOCFields({recordId:this.recordId,objectName:this.objectName,fieldSetName:this.fieldSetName})
                .then(result => {
                    this.allFields = result.fieldsList;
                })
                .catch(error => {
                    this.errorOnCallback = error;
                });

            await fetchOCFields({recordId:this.recordId,objectName:this.objectName,fieldSetName:this.fieldSetName_Bank_Info})
                .then(result => {
                    this.allBankFields = result.fieldsList;
                })
                .catch(error => {
                    this.errorOnCallback = error;
                });
            
            await handleSalesOrder({recordId:this.soRecId})
                .then(data => {
                    this.salesOrderData = data;
                    this.template.querySelector('[data-id="'+CONST_ACCOUNT+'"]').value = data.Account__c;
                    this.template.querySelector('[data-id="'+CONST_SALES_ORDER_ID+'"]').value = data.Id;
                    this.isSpinner = false;
                })
                .catch(error => {
                    console.log(error);
                });
        } else {
            this.isSpinner = false;
            this.handleError(this.IsValidUserForOC);
            this.handleCancel();
        }
    }

    handleFieldChange(event) {
        let fieldName = event.target.fieldName != undefined ? event.target.fieldName : event.target.label;
        let value = event.target.value;
        console.log('fieldName --> '+fieldName);
        console.log('fieldName val --> '+event.target.value);

        switch (fieldName) {
            case CONST_TYPE_OF_CHARGE_LABEL:
                
                this.disableSubType = true;
                this.handleTypeChange(value);
                if(value == 'Debit Memo') {
                    this.disableSubType = false;
                }

            // Check VAT eligibility on type change // Added by Anil (154 to 167 line)
            const vatTypes = VAT_ELIGIBLE_TYPES.split(',').map(type => type.trim());
            if (vatTypes.includes(value)) {
                // If amount already entered, recalculate VAT
                const amountWithoutVAT = this.template.querySelector('[data-id="'+CONST_AMOUNT_WITHOUT_VAT+'"]').value;
                if (amountWithoutVAT) {
                    this.calculateVAT(amountWithoutVAT, this.vatPercentage);
                }
            } else {
                // Not VAT-eligible → clear VAT & total
                this.template.querySelector('[data-id="'+CONST_VAT_AMOUNT+'"]').value = 0;
                const amountWithoutVAT = this.template.querySelector('[data-id="'+CONST_AMOUNT_WITHOUT_VAT+'"]').value;
                this.template.querySelector('[data-id="'+CONST_AMOUNT+'"]').value = amountWithoutVAT || 0;
            }
                
                break;
            case CONST_AMOUNT_WITHOUT_VAT:

                this.actualAmount = value;
                this.handleAmount(value);

                // Call calculateVAT only if TypeOfCharge is in custom label list // Added by Anil (176 to 186 line)
                const selectedType = this.template.querySelector('[data-id="'+CONST_TYPE_OF_CHARGE+'"]').value;
                const vatTypes2 = VAT_ELIGIBLE_TYPES.split(',').map(type => type.trim());

                if (vatTypes2.includes(selectedType)) {
                    this.calculateVAT(value, this.vatPercentage);
                } else {
                    // Clear VAT and total if not applicable
                    this.template.querySelector('[data-id="'+CONST_VAT_AMOUNT+'"]').value = 0;
                    this.template.querySelector('[data-id="'+CONST_AMOUNT+'"]').value = value;
                }

                break;
            case CONST_AMOUNT_RECEIVED:

                break;
            case CONST_VAT_AMOUNT:

                event.preventDefault();
                break;
            default:
                break;
        }
    }

    handleAmount(value) {
        let typeOfCharge = this.template.querySelector('[data-id="'+CONST_TYPE_OF_CHARGE+'"]').value;
        /*if(typeOfCharge == this.typeOfChargeOptions[4].label || typeOfCharge == this.typeOfChargeOptions[5].label){ //Transfer fee or Legal
            this.template.querySelector('[data-id="'+CONST_VAT_AMOUNT+'"]').value = value * 0.05;
            this.template.querySelector('[data-id="'+CONST_AMOUNT+'"]').value = value * 1.05;
        } else {*/
            this.template.querySelector('[data-id="'+CONST_VAT_AMOUNT+'"]').value = 0;
            this.template.querySelector('[data-id="'+CONST_AMOUNT+'"]').value = value;
        //}
    }
    handleTypeChange(value) {
        if(value == this.typeOfChargeOptions[0].label) { //If Refund, then show bank section
            this.showRefundSection = true;
            setTimeout(() => {
                this.activeSectionName = ['A','B'];
                this.template.querySelector('[data-id="'+CONST_PAYMENT_METHOD+'"]').value = CONST_WIRE_TRANSFER;
            }, 100);
        } else {
            this.activeSectionName = ['A'];
            this.showRefundSection = false;
        }
    }

    calculateVAT(amount, vatPercentage) {
        let vatAmount = (amount * vatPercentage) / 100;
        this.vatAmount = vatAmount.toFixed(2);

        this.template.querySelector('[data-id="'+CONST_VAT_AMOUNT+'"]').value = parseFloat(this.vatAmount);
        this.template.querySelector('[data-id="'+CONST_AMOUNT+'"]').value = parseFloat(amount) + parseFloat(this.vatAmount);

        return parseFloat(this.vatAmount);
    }


    handleSave(event) {
        event.preventDefault();
        let subType = this.template.querySelector('[data-id="'+CONST_SUB_TYPE_OF_CHARGE+'"]')!=null ? this.template.querySelector('[data-id="'+CONST_SUB_TYPE_OF_CHARGE+'"]').value : '';
        if(!this.disableSubType && subType!=null && subType!=undefined && subType!='') {
            this.validateFields(event);
        } else {
            this.validateFields(event);
        }
        
    }

    validateFields(event) {
        event.preventDefault();
        this.isSpinner = true;

        let soOtherChargesObj = { 'sobjectType': 'SalesOrderOtherCharges__c' };
        let ocFields = this.allFields;
        for(let ys in ocFields) { 
            //console.log('ys -> '+event.detail.fields[ys]);
            soOtherChargesObj[ocFields[ys].APIName] = this.template.querySelector('[data-id="'+ocFields[ys].APIName+'"]').value;
        }
        soOtherChargesObj['Is_Manual_Entry__c'] = true;
        soOtherChargesObj[CONST_TYPE_OF_CHARGE] = this.template.querySelector('[data-id="'+CONST_TYPE_OF_CHARGE+'"]').value;
        
        if(this.showRefundSection) {
            
            let ocBankFields = this.allBankFields;
            for(let ys in ocBankFields) { 
                soOtherChargesObj[ocBankFields[ys].APIName] = this.template.querySelector('[data-id="'+ocBankFields[ys].APIName+'"]').value;
            }
            soOtherChargesObj[CONST_TYPE_OF_CHARGE] = CONST_DEBIT_MEMO;
            soOtherChargesObj[CONST_SUB_TYPE_OF_CHARGE] = CONST_CUSTOMER_REFUND;
        }
        
        handleInsert({ocCharge:soOtherChargesObj})
        .then(data=> {
            console.log('data -> '+data);
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: data,
                    objectApiName: 'SalesOrderOtherCharges__c',
                    actionName: 'view'
                }
            });
        })
        .catch(error=> {
            console.log('error -> '+error);
            this.isSpinner = false;
        });
    }

    handleSuccess() {
        const toastEvent = new ShowToastEvent({
            title: 'Success',
            variant: 'success',
            mode: 'dismissable',
            message: 'Record Saved Successfully'
        });
        this.dispatchEvent(toastEvent);
    }

    handleCancel() {
        this.isSpinner = true;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.soRecId,
                objectApiName: 'SalesOrder__c',
                actionName: 'view'
            }
        });
    }

    handleError(errormessage) {
        const toastEvent = new ShowToastEvent({
            title: 'Error',
            variant: 'error',
            mode: 'dismissable',
            message: errormessage
        });
        this.dispatchEvent(toastEvent);
    }

}