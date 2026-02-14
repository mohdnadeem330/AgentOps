import { LightningElement, track, api, wire } from 'lwc';
import getRelatedAccountNames from '@salesforce/apex/JointOwnersOppController.getRelatedAccountNames';
import getTotalSharePercentage from '@salesforce/apex/JointOwnersOppController.getTotalSharePercentage';
import saveRecord from '@salesforce/apex/JointOwnersOppController.saveJointOwner';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CreateJointOwnersOpp extends NavigationMixin(LightningElement) {
    @track customername = [];
    @track custName;
    @api recordId;
    @track recId;
    @track disableSave = true;
    @track intdigit;
    @track decdigit;
    @track callSave;
    @track relationType;
    @track showData = [];
    @track isLoading = false;
    @track totalSharePercentage = 0;

    connectedCallback() {
        this.recId = new URL(window.location.href).searchParams.get("c__rId");

        console.log('#### ----------->this.recId ',this.recId);

        getRelatedAccountNames({
            recordId: this.recId
        }).then(result => {
            if (result) {
                this.showData = result;
                for (let i = 0; i < result.length; i++) {
                    this.customername = [... this.customername, { value: result[i].RelatedAccount__r.Id, label: result[i].RelatedAccount__r.Name, Id: result[i].Id, Relation: result[i].RelationshipType__c }];
                }
            }
        }).catch(error => {
            console.log('error ', error);
        });

        getTotalSharePercentage({
            recordId: this.recId
        }).then(result => {
            if (result) {
                this.totalSharePercentage = JSON.parse(JSON.stringify(result));
            }
        }).catch(error => {
            console.log('error ', error);
        })
    }

    get AccountList() {
        return this.customername;
    }

    @track custId;
    handleChange(event) {
        this.custName = event.target.value;
        this.customername.forEach((number) => {
            if (number.value == this.custName) {
                this.relationType = number.Relation;

            }
        });
        this.disableSave = false;
    }

    sharePercentageChange(event) {
        this.shareper = event.target.value;

        if ((parseFloat(this.shareper) + this.totalSharePercentage) > 99) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    variant: 'error',
                    message: 'Total Joint Owner Share Percentage cannot exceed 99%',
                })
            );
        }
    }
    handleSave() {
        this.saveRecord();
    }

    handleCancel() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recId,
                objectApiName: 'Opportunity',
                actionName: 'view'
            }
        });
    }

    saveRecord() {
        console.log('>>relationtype>>>' + this.relationType);
        if (this.shareper == undefined || this.shareper == null || this.shareper == '') {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    variant: 'error',
                    message: 'Joint Owner Share Percentage cannot be Blank',
                })
            );
        } else if ((parseFloat(this.shareper) + this.totalSharePercentage) > 99) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    variant: 'error',
                    message: 'Total Joint Owner Share Percentage cannot exceed 99%',
                })
            );
        } else {
            this.isLoading = true;
            this.totalSharePercentage = parseFloat(this.shareper) + this.totalSharePercentage;
            var createRec = {
                'sobjectType': 'JointOwner__c',
                'Account__c': this.custName,
                'Opportunity__c': this.recId,
                'SharePercentage__c': this.shareper,
                'RelationshipType__c': this.relationType
            }
            saveRecord({
                JointOwnerRec: createRec
            }).then(joId => {
                if (joId) {
                    this.isLoading = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            variant: 'success',
                            message: 'Joint Owner Successfully created',
                        }),
                    );

                    this[NavigationMixin.Navigate]({
                        type: 'standard__recordRelationshipPage',
                        attributes: {
                            recordId: this.recId,
                            objectApiName: 'Opportunity',
                            relationshipApiName: 'JointOwnersOpportunity__r',
                            actionName: 'view'
                        }
                    });
                }
            }).catch(error => {
                this.isLoading = false;
                if (error.body && error.body.message) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            variant: 'error',
                            message: error.body.message,
                        }),
                    );
                } else {
                    console.log('error ', error);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            variant: 'error',
                            message: error,
                        }),
                    );
                }
            });
        }
    }
}