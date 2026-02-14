import { LightningElement, track, api } from 'lwc';
import getRelatedAccountNames from '@salesforce/apex/CreateJointOwnersController.getRelatedAccountNames';
import getTotalSharePercentage from '@salesforce/apex/CreateJointOwnersController.getTotalSharePercentage';
import validateJointOwner from '@salesforce/apex/JointOwnerandThirdpartyValidation.validateJointOwner';
import validateAccountDocumentsLWC from '@salesforce/apex/JointOwnerandThirdpartyValidation.validateAccountDocumentsLWC';
import saveRecord from '@salesforce/apex/CreateJointOwnersController.saveJointOwner';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CreateJointOwners extends NavigationMixin(LightningElement) {
    @track customername = [];
    @track custName;
    @api recordId;
    @track recId;
    @track disableSave = true;
    @track relationType;
    @track showData = [];
    @track isLoading = false;
    @track totalSharePercentage = 0;
    @track shareper;
    @track expectedAmount;

    connectedCallback() {
        this.recId = new URL(window.location.href).searchParams.get("c__rId") || this.recordId;

        Promise.all([
            getRelatedAccountNames({ recordId: this.recId }),
            getTotalSharePercentage({ recordId: this.recId })
        ])
        .then(([accounts, totalShare]) => {
            if (accounts) {
                this.showData = accounts;
                this.customername = accounts.map(acc => ({
                    value: acc.RelatedAccount__r.Id,
                    label: acc.RelatedAccount__r.Name,
                    Id: acc.Id,
                    Relation: acc.RelationshipType__c
                }));
                }
            if (totalShare) {
                this.totalSharePercentage = parseFloat(totalShare);
            }
        })
        .catch(error => {
            console.log('Error in connectedCallback: ', error);
        });
    }

    get AccountList() {
        return this.customername;
    }

    handleChange(event) {
        this.custName = event.target.value;
        const selectedAccount = this.customername.find(acc => acc.value === this.custName);
        this.relationType = selectedAccount ? selectedAccount.Relation : null;
        this.disableSave = !this.custName;
            }

    get isExpectedAmountRequired() {
        return this.relationType && (this.relationType.includes('Joint Owner') || this.relationType.includes('Third Party'));
    }

    get isExpectedAmountRequired() {
        return this.relationType && (this.relationType.includes('Joint Owner') || this.relationType.includes('Third Party'));
    }

    sharePercentageChange(event) {
        this.shareper = event.target.value;
        if ((parseFloat(this.shareper) + parseFloat(this.totalSharePercentage)) > 99) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    variant: 'error',
                    message: 'Total Joint Owner Share Percentage cannot exceed 99%',
                })
            );
        }
    }

    expectedAmountChange(event) {
        this.expectedAmount = event.target.value;
    }

    handleSave() {
        this.saveRecord();
    }

    handleCancel() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recId,
                objectApiName: 'SalesOrder__c',
                actionName: 'view'
            }
        });
    }

    async saveRecord() {
        if (!this.handleCheckValidation()) {
            return;
        }

        if (!this.shareper) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    variant: 'error',
                    message: 'Joint Owner Share Percentage cannot be blank',
                })
            );
            return;
        }

        if ((parseFloat(this.shareper) + parseFloat(this.totalSharePercentage)) > 99) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    variant: 'error',
                    message: 'Total Joint Owner Share Percentage cannot exceed 99%',
                })
            );
            return;
            }

        try {
            this.isLoading = true;

            // Validate Joint Owner
            const validation = await validateJointOwner({ accountId: this.custName });
            if (!validation.isValid) {
                this.isLoading = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        variant: 'error',
                        message: validation.errorMessage,
                    })
                );
                return;
            }

            // Validate Account Documents
            const result = await validateAccountDocumentsLWC({ accountId: this.custName });
            if (!result.isValid) {
                this.isLoading = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        variant: 'error',
                        message: result.errorMessage,
                    })
                );
                return;
            }

            const createRec = {
                sobjectType: 'JointOwner__c',
                Account__c: this.custName,
                SalesOrder__c: this.recId,
                SharePercentage__c: this.shareper,
                Expected_Amount__c: this.expectedAmount,
                RelationshipType__c: this.relationType
            };

            const joId = await saveRecord({ JointOwnerRec: createRec });
                if (joId) {
                this.totalSharePercentage += parseFloat(this.shareper);
                    this.isLoading = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            variant: 'success',
                        message: 'JointOwner successfully created',
                    })
                    );

                    this[NavigationMixin.Navigate]({
                        type: 'standard__recordRelationshipPage',
                        attributes: {
                            recordId: this.recId,
                            objectApiName: 'SalesOrder__c',
                            relationshipApiName: 'Joint_OwnersSalesOrder__r',
                            actionName: 'view'
                        }
                    });
                }
        } catch (error) {
                this.isLoading = false;
            const errorMsg = error?.body?.message?.replace('Insert failed. First exception on row 0; first error: FIELD_CUSTOM_VALIDATION_EXCEPTION,','') || 'Unknown error';
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            variant: 'error',
                    message: errorMsg,
                })
                    );
                }
    }

    handleCheckValidation() {
        let isValid = true;
        const inputFields = this.template.querySelectorAll('.fieldvalidate');
        inputFields.forEach(inputField => {
            if (!inputField.checkValidity()) {
                inputField.reportValidity();
                isValid = false;
            }
            });

        const expectedAmountField = this.template.querySelector('.expectedAmountField');
        if (expectedAmountField) {
            if (this.isExpectedAmountRequired && !expectedAmountField.value) {
                expectedAmountField.setCustomValidity('Expected Amount is required when a third party or joint owner is added.');
                isValid = false;
            } else {
                expectedAmountField.setCustomValidity('');
        }
            expectedAmountField.reportValidity();
        }

        return isValid;
    }

    handleCheckValidation() {
        let isValid = true;
        let inputFields = this.template.querySelectorAll('.fieldvalidate');
        inputFields.forEach(inputField => {
            if(!inputField.checkValidity()) {
                inputField.reportValidity();
                isValid = false;
            }
        });

        // Target only the ExpectedAmount field
        const expectedAmountField = this.template.querySelector('.expectedAmountField');

        // Example: show message if the field is required but empty
        if (this.isExpectedAmountRequired && (!expectedAmountField.value || expectedAmountField.value === '')) {
            expectedAmountField.setCustomValidity('Expected Amount is required when a third party or joint owner is added.');
            isValid = false;
        } else {
            expectedAmountField.setCustomValidity('');
        }

        expectedAmountField.reportValidity();

        return isValid;
    }
}