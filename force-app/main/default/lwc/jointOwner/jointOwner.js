import { api, LightningElement, track, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from "lightning/actions";

import getServiceRequestDetail from '@salesforce/apex/JointOwnerController.getServiceRequestDetail';
import saveJointOwner from '@salesforce/apex/JointOwnerController.saveJointOwner';

export default class JointOwner extends NavigationMixin(LightningElement) {
    @api recordId;
    @track columns = [];
    @track accountOptions = [];
    @track salesOrderOptions = {};
    @track lineOptions = {};
    @track isLoading = false;
    @track headerName = 'Manage Owners';

    @track isAdditionJointOwner = false;
    @track isDeletionJointOwner = false;
    @track isOwnershipChange = false;
    @track isSharePercentageChange = false;
    @track srType = '';

    @track srData = {};
    @track totalJointOwnerShare = 0;
    @track jointOwnerList = [];
    @track deleteNewJOList = [];
    @track disableSave = true;
    @track newRelationshipOptions = [
        { label: 'Primary Owner', value: 'Primary Owner' },
        { label: 'Joint Owner', value: 'Joint Owner' }
    ]

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
        }
    }

    async connectedCallback() {
        console.log('recordId>>>' + this.recordId);
        await this.getServiceRequest();
    }

    async getServiceRequest() {
        this.isLoading = true;
        this.srData = {};
        this.jointOwnerList = [];
        console.log('getServiceRequest');

        await getServiceRequestDetail({
            srId: this.recordId
        }).then(result => {
            let tempResult = JSON.parse(result);
            console.log('result>>>', tempResult);

            this.srData = JSON.parse(JSON.stringify(tempResult));

            if (this.srData.srType == 'Addition Joint Owner') {
                this.isAdditionJointOwner = true
            } else if (this.srData.srType == 'Deletion Joint Owner') {
                this.isDeleteJointOwner = true;
            } else if (this.srData.srType == 'Ownership Change') {
                this.isOwnershipChange = true;
            } else if (this.srData.srType == 'Share Percentage Change') {
                this.isSharePercentageChange = true;
            }
            this.srType = this.srData.srType;

            for (let jo of this.srData.subJointOwnerList) {
                this.jointOwnerList.push(jo);
            }
            for (let jo of this.srData.jointOwnerDetailList) {
                this.jointOwnerList.push(jo);
            }

            let uniqueList = [];
            for (let jo of this.jointOwnerList) {
                uniqueList.push(jo.accountId);
            }

            this.accountOptions = [...this.accountOptions];

            let tempRelatedAccounts = [];
            for (let acc of tempResult.relatedAccountList) {
                if (!uniqueList.includes(acc.accountId)) {
                    tempRelatedAccounts.push({ 'label': acc.accountName, 'value': acc.accountId });
                }
            }
            this.accountOptions = tempRelatedAccounts;

            this.columns.push({ title: 'Joint Owner', fieldName: 'jointOwner', type: 'picklist-text', style: 'overflow: initial; word-break: break-word; white-space: pre-line; overflow-wrap: break-word;' });
            this.columns.push({ title: 'Ownership Type', fieldName: 'ownershipType', type: 'text', readonly: true });
            this.columns.push({ title: 'Relationship Type', fieldName: 'relationType', type: 'text', readonly: true });
            if (!this.isOwnershipChange) {
                this.columns.push({ title: 'Share Percentage', fieldName: 'sharePercentage', type: 'percent' });
            }
            if (this.isOwnershipChange) {
                this.columns.push({ title: 'New Ownership Type', fieldName: 'newRelationType', type: 'picklist-text', style: 'overflow: initial;' });
            }
            this.columns.push({ title: '', fieldName: 'delete', type: 'button' });

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

    checkValidation(isSave, checkSame) {
        let isError = false;
        let errorMessage = '';

        let uniqueList = [];
        for (let jo of this.jointOwnerList) {
            if (checkSame) {
                if (uniqueList.length > 0 && uniqueList.includes(jo.accountId)) {
                    isError = true;
                    errorMessage = 'Please do not select the same Joint Owner. Kindly use the existing one.'
                    break;
                } else {
                    uniqueList.push(jo.accountId);
                }
            }
            if (checkSame && !isSave) {
                continue;
            }

            if (isSave) {
                if (jo.jointOwner == undefined || jo.jointOwner == null || jo.jointOwner == '') {
                    isError = true;
                    errorMessage = 'Please select Joint Owner from dropdown or delete empty line to proceed.';
                } else if ((jo.jointOwnerId == undefined || jo.jointOwnerId == null || jo.jointOwnerId == '') && (jo.sharePercentage == undefined || jo.sharePercentage == null || jo.sharePercentage == '' || jo.sharePercentage == 0)) {
                    isError = true;
                    errorMessage = 'Please enter share percentage for all the Joint Owner/s.';
                }
            }
        }

        if (isSave && !isError) {
            this.totalJointOwnerShare = 0;
            for (let jo of this.jointOwnerList) {
                this.totalJointOwnerShare += jo.sharePercentage;
                if (jo.newRelationType == 'Primary Owner' && (jo.sharePercentage == null || jo.sharePercentage < 1)) {
                    isError = true;
                    errorMessage = 'Primary Owner Share Percentage cannot be less than 1%';
                    break;
                }
            }
            if (!isError && this.totalJointOwnerShare != 100) {
                isError = true;
                errorMessage = 'Total share percentage of Primary & Joint Owner/s should 100%';
            }
        }
        
        if (isSave && !isError) {
            let isNewPrimaryOwner = false;
            let primaryOwnerCount = 0;
            for (let jo of this.jointOwnerList) {
                if (jo.newRelationType == 'Primary Owner') {
                    isNewPrimaryOwner = true;
                    primaryOwnerCount += 1;
                }
            }
            if (!isNewPrimaryOwner) {
                isError = true;
                errorMessage = 'Please ensure one of the owners are Primary Owner at all times.';
            } else if (primaryOwnerCount > 1) {
                isError = true;
                errorMessage = 'Please note all the units need to have only one Primary Owner.';
            }
        }

        if (!this.isDeleteJointOwner && isSave) {
            for (let jo of this.jointOwnerList) {
                if (jo.sharePercentage == undefined || jo.sharePercentage == null || jo.sharePercentage == '' || jo.sharePercentage == 0) {
                    isError = true;
                    errorMessage = 'Share percentage cannot be null or zero for ' + this.srType;
                    break;
                }
            }
        }

        if (this.isOwnershipChange && isSave) {
            for (let jo of this.jointOwnerList) {
                if (jo.newRelationType == 'Primary Owner' && jo.ownershipType == 'Primary Owner') {
                    isError = true;
                    errorMessage = 'Ownership cannot be same for ' + this.srType;
                    break;
                }
            }
        }

        if (isError) {
            console.log('error>>>' + errorMessage);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    variant: 'error',
                    message: errorMessage,
                })
            );
        } else {
            this.disableSave = true;
        }
        return isError;
    }

    async handleChange(event) {
        console.log('name>>>' + event.detail.recordIndex);
        console.log('fieldName>>>' + event.detail.fieldName);
        console.log('value>>>' + event.detail.value);

        let recordIndex = event.detail.recordIndex;
        let fieldName = event.detail.fieldName;
        let value = event.detail.value;
        if (fieldName == 'jointOwner') {
            this.disableSave = false;
            this.jointOwnerList[recordIndex][fieldName] = value;
            for (let acc of this.srData.relatedAccountList) {
                if (acc.accountId == value) {
                    this.jointOwnerList[recordIndex].accountId = value;
                    this.jointOwnerList[recordIndex].accountName = acc.accountName;
                    this.jointOwnerList[recordIndex].relationType = acc.relationType;
                    this.jointOwnerList[recordIndex].newRelationType = 'Joint Owner';
                    break;
                }
            }
        } else if (fieldName == 'sharePercentage') {
            this.jointOwnerList[recordIndex][fieldName] = parseFloat(value);
        } else if (fieldName == 'newRelationType') {
            this.jointOwnerList[recordIndex][fieldName] = value;
        }
        console.log('jointOwnerList>>>' + JSON.stringify(this.jointOwnerList));
        this.checkValidation(false, false);
    }

    addJointOwner(event) {
        this.disableSave = false;
        let newRow = {
            accountId: '',
            accountName: '',
            relationType: '',
            sharePercentage: 0
        }
        this.jointOwnerList.push(newRow);
    }

    deleteJointOwner(event) {
        let rowIndex = event.detail.recordIndex;
        if (confirm('Are you sure you want to delete?')) {
            this.deleteNewJOList.push(this.jointOwnerList[rowIndex].Id);
            this.jointOwnerList.splice(rowIndex, 1);
        }
    }

    async handleSave(event) {
        console.log('handleSave');

        let isError = this.checkValidation(true, true);

        if (!isError) {
            this.isLoading = true;
            let jointOwner = JSON.stringify(this.jointOwnerList);
            let deleteNewJO = this.deleteNewJOList.toString()
            await saveJointOwner({
                jointOwner: jointOwner,
                srId: this.recordId,
                deleteNewJO: deleteNewJO
            }).then(result => {
                this.getServiceRequest();
                this.isLoading = false;
                this.backToServiceRequest();
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
    }

    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    backToServiceRequest() {
        //let redirectionPageUrl;
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'HexaBPM__Service_Request__c',
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
}