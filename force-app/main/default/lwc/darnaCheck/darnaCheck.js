import { api, LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from "lightning/actions";
import { CurrentPageReference } from 'lightning/navigation';
import getCaseDetails from '@salesforce/apex/DarnaCheckController.getCaseDetails';
import updateContactMembershipNumber from '@salesforce/apex/DarnaCheckController.updateContactMembershipNumber';
import getUserProfileAPI from '@salesforce/apex/DarnaServices.getUserProfileAPI';
import getUserPointsAPI from '@salesforce/apex/DarnaServices.getUserPointsAPI';
import getAccessTokenAPI from '@salesforce/apex/DarnaServices.getAccessTokenAPI';
import redeemPointsAPI from '@salesforce/apex/DarnaServices.redeemPointsAPI';
import otpRequest from '@salesforce/apex/DarnaServices.otpRequest';
import createReceiptAcknowledgementForRedemption from '@salesforce/apex/DarnaCheckController.createReceiptAcknowledgementForRedemption';
import { updateRecord } from 'lightning/uiRecordApi';
import getVFDomainURL from "@salesforce/apex/Utilities.getVFDomainURL";

export default class PaymentPlanFromSR extends NavigationMixin(LightningElement) {

    @api recordId;
    @track errorMessageToDisplay = '';
    @track errorHeader = 'Error Message';
    @track error = { message: '' };
    @track isLoaded = false;
    @track contactRecord;
    @track caseRecord;
    @track email;
    @track mobile;
    @track token = '';
    @track userProfileInfo;
    @track userPointsInfo;
    @track otpResponse;
    @track redeemPointsResponse;
    @track userProfileInfoVisable = false;
    @track membershipNumber = '';
    @track mode = 'amount';
    @track amount;
    @track otp;
    @track redemptionAgainst;
    @track otpSent = false;
    @track redeemFieldsReadOnly = false;


    get options() {
        return [
            { label: 'Points', value: 'points' },
            { label: 'Amount', value: 'amount' },
        ];
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
        }
    }

    async connectedCallback() {

        this.isLoaded = true;

        getCaseDetails({ recordId: this.recordId }).then(result => {

            this.caseRecord = result;
            this.contactRecord = result.Contact;
            if (this.contactRecord != null) {
                this.email = this.contactRecord.Email;
                this.mobile = this.contactRecord.MobilePhone;
                this.membershipNumber = this.contactRecord.DarnaMembershipNumber__c;
            }


            console.log(result);
            this.isLoaded = false;

        }).catch(error => {
            this.error = error;
            this.reduceErrors(error);
            this.showToast(this.errorHeader, this.errorMessageToDisplay, 'error');
            this.isLoaded = false;
        })
    }

    updateRecordView(recordId) {
        this.closeAction();
        this.isLoaded = false;
        setTimeout(() => {
            eval("$A.get('e.force:refreshView').fire();");
        }, 1000);
    }

    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleFieldsChange(event) {

        if (event.target.name == 'Email') {
            this.email = event.target.value;

        } else if (event.target.name == 'MobileNumber') {
            this.mobile = event.target.value;

        } else if (event.target.name == 'mode') {
            this.mode = event.target.value;

        } else if (event.target.name == 'amount') {
            this.amount = event.target.value;

        } else if (event.target.name == 'otp') {
            this.otp = event.target.value;

        } else if (event.target.name == 'RedemptionAgainst') {
            this.redemptionAgainst = event.target.value;
        }
    }
    handleRegistrationCheck() {

        this.userPointsInfo = null;
        this.errorMessageToDisplay = '';
        this.isLoaded = true;
        this.userProfileInfo = null;

        if (this.token == '') {

            getAccessTokenAPI().then(result => {

                this.token = result;

                getUserProfileAPI({ email: this.email, mobile: this.mobile, token: this.token }).then(result => {


                    if (result.message != 'success') {
                        this.errorMessageToDisplay = result.message;
                        this.errorHeader = 'Registration Check';
                        this.isLoaded = false;

                    } else {
                        this.userProfileInfo = result;
                        this.membershipNumber = result.membership_number;

                        if (this.contactRecord.DarnaMembershipNumber__c == null || this.contactRecord.DarnaMembershipNumber__c != this.membershipNumber) {
                            updateContactMembershipNumber({ contactRecord: this.contactRecord, membershipNumber: this.membershipNumber }).then(result => {
                                this.isLoaded = false;
                            }).catch(error => {
                                this.error = error;
                                this.reduceErrors(error);
                                this.showToast(this.errorHeader, this.errorMessageToDisplay, 'error');
                                this.isLoaded = false;
                            })

                        } else {
                            this.isLoaded = false;
                        }

                    }

                }).catch(error => {
                    this.error = error;
                    this.reduceErrors(error);
                    this.showToast(this.errorHeader, this.errorMessageToDisplay, 'error');
                    this.isLoaded = false;
                })

            }).catch(error => {
                this.error = error;
                this.reduceErrors(error);
                this.showToast(this.errorHeader, this.errorMessageToDisplay, 'error');
                this.isLoaded = false;
            })
        } else {
            getUserProfileAPI({ email: this.email, mobile: this.mobile, token: this.token }).then(result => {

                if (result.message != 'success') {
                    this.errorMessageToDisplay = result.message;
                    this.errorHeader = 'Registration Check';
                    this.isLoaded = false;

                } else {
                    this.userProfileInfo = result;
                    this.membershipNumber = result.membership_number;

                    if (this.contactRecord.DarnaMembershipNumber__c == null) {
                        updateContactMembershipNumber({ contactRecord: this.contactRecord, membershipNumber: this.membershipNumber }).then(result => {
                            this.isLoaded = false;
                        }).catch(error => {
                            this.error = error;
                            this.reduceErrors(error);
                            this.showToast(this.errorHeader, this.errorMessageToDisplay, 'error');
                            this.isLoaded = false;
                        })

                    } else {
                        this.isLoaded = false;
                    }
                }

            }).catch(error => {
                this.error = error;
                this.reduceErrors(error);
                this.showToast(this.errorHeader, this.errorMessageToDisplay, 'error');
                this.isLoaded = false;
            })
        }
    }

    handlePointsCheck() {

        this.errorMessageToDisplay = '';
        this.isLoaded = true;
        this.userPointsInfo = null;

        if (this.userProfileInfo == null || this.userProfileInfo == '') {
            this.errorMessageToDisplay = 'Kindly check if the customer is registered to DARNA by \'Registration Check\' button.';
            this.errorHeader = 'Points Check';
            this.isLoaded = false;
        } else {

            if (this.token == '') {

                getAccessTokenAPI().then(result => {

                    this.token = result;

                    getUserPointsAPI({ membershipNumber: this.membershipNumber, token: this.token }).then(result => {


                        if (result.message != 'success') {
                            this.errorMessageToDisplay = result.message;
                            this.errorHeader = 'Points Check';
                            this.isLoaded = false;

                        } else {
                            this.userPointsInfo = result;
                            this.isLoaded = false;
                        }

                        console.log(this.userPointsInfo);


                    }).catch(error => {
                        this.error = error;
                        this.reduceErrors(error);
                        this.showToast(this.errorHeader, this.errorMessageToDisplay, 'error');
                        this.isLoaded = false;
                    })

                }).catch(error => {
                    this.error = error;
                    this.reduceErrors(error);
                    this.showToast(this.errorHeader, this.errorMessageToDisplay, 'error');
                    this.isLoaded = false;
                })
            } else {
                getUserPointsAPI({ membershipNumber: this.membershipNumber, token: this.token }).then(result => {


                    if (result.message != 'success') {
                        this.errorMessageToDisplay = result.message;
                        this.errorHeader = 'Points Check';
                        this.isLoaded = false;
                    } else {
                        this.userPointsInfo = result;
                        this.isLoaded = false;
                    }
                    console.log(this.userPointsInfo);


                }).catch(error => {
                    this.error = error;
                    this.reduceErrors(error);
                    this.showToast(this.errorHeader, this.errorMessageToDisplay, 'error');
                    this.isLoaded = false;
                })
            }

        }
    }

    async handleRedeemPoints() {


        this.errorMessageToDisplay = '';
        this.isLoaded = true;

        if (this.caseRecord.SalesOrder__c == null) {
            this.errorMessageToDisplay = 'Kindly populate Sales Order to redeem the points';
            this.errorHeader = 'Redeem Points';
            this.isLoaded = false;
        } else {

            let redemptionAgainstTarget = await this.template.querySelector('[data-id="RedemptionAgainst"]');

            if (this.redemptionAgainst == null || this.redemptionAgainst == '') {
                redemptionAgainstTarget.setCustomValidity('Complete this field.');
            } else {
                redemptionAgainstTarget.setCustomValidity('');
            }
            redemptionAgainstTarget.reportValidity();


            let amountTarget = await this.template.querySelector('[data-id="amount"]');

            if (this.amount == null || this.amount == '') {
                amountTarget.setCustomValidity('Complete this field.');
            } else {
                amountTarget.setCustomValidity('');
            }
            amountTarget.reportValidity();

            const isCorrectInput = await [...this.template.querySelectorAll('lightning-input'), ...this.template.querySelectorAll('lightning-combobox')]
                .reduce((validSoFar, inputField) => {
                    inputField.reportValidity();
                    return validSoFar && inputField.checkValidity();
                }, true);

            console.log(isCorrectInput);
            console.log(this.mode);
            if (isCorrectInput) {

                if (this.membershipNumber == null || this.membershipNumber == '') {
                    this.errorMessageToDisplay = 'Kindly check if the customer is registered to DARNA by \'Registration Check\' button.';
                    this.errorHeader = 'Redeem Points';
                    this.isLoaded = false;
                } else {

                    if (this.mode == 'points') {

                        if (this.amount < parseFloat(this.userPointsInfo.minimum_redeemable_points)) {
                            amountTarget.setCustomValidity('Minimum Redeemable Points is ' + parseFloat(this.userPointsInfo.minimum_redeemable_points));
                            amountTarget.reportValidity();
                            this.errorMessageToDisplay = 'Minimum Redeemable Points is ' + parseFloat(this.userPointsInfo.minimum_redeemable_points);
                            this.errorHeader = 'Redeem Points';

                        } else if (this.amount > parseFloat(this.userPointsInfo.available_points)) {

                            amountTarget.setCustomValidity('Insufficient balance, the entered amount of points is more than the available points to redeem');
                            amountTarget.reportValidity();

                            this.errorMessageToDisplay = 'Insufficient balance, the entered amount of points is more than the available points to redeem';
                            this.errorHeader = 'Redeem Points';
                        }
                    } else {
                        if (this.amount < parseFloat(this.userPointsInfo.minimum_redeemable_amount)) {

                            amountTarget.setCustomValidity('Minimum Redeemable Amount is ' + parseFloat(this.userPointsInfo.minimum_redeemable_amount));
                            amountTarget.reportValidity();

                            this.errorMessageToDisplay = 'Minimum Redeemable Amount is ' + parseFloat(this.userPointsInfo.minimum_redeemable_amount);
                            this.errorHeader = 'Redeem Points';

                        } else if (this.amount > parseFloat(this.userPointsInfo.amount)) {

                            amountTarget.setCustomValidity('Insufficient balance, the entered amount  is more than the available amount to redeem');
                            amountTarget.reportValidity();

                            this.errorMessageToDisplay = 'Insufficient balance, the entered amount  is more than the available amount to redeem';
                            this.errorHeader = 'Redeem Points';
                        }
                    }

                    const isCorrectInput2 = await [...this.template.querySelectorAll('lightning-input'), ...this.template.querySelectorAll('lightning-combobox')]
                        .reduce((validSoFar, inputField) => {
                            inputField.reportValidity();
                            return validSoFar && inputField.checkValidity();
                        }, true);

                    if (isCorrectInput2) {

                        console.log(this.token);

                        otpRequest({ membershipNumber: this.membershipNumber, token: this.token }).then(result => {

                            console.log(JSON.stringify(result));
                            if (result.success != 'true') {
                                this.errorMessageToDisplay = result.message;
                                this.errorHeader = 'Redeem Points';

                            } else {
                                this.otpResponse = result;
                                this.otpSent = true;
                            }

                            this.isLoaded = false;

                        }).catch(error => {
                            this.error = error;
                            this.reduceErrors(error);
                            this.showToast(this.errorHeader, this.errorMessageToDisplay, 'error');
                            this.isLoaded = false;
                        })
                    } else {
                        this.isLoaded = false;
                    }

                    /*getUserPointsAPI({ membershipNumber: this.membershipNumber, token: this.token }).then(result => {
        
                        if (result.message != 'success') {
                            this.errorMessageToDisplay = result.message;
                            this.errorHeader = 'Points Check';
                            this.isLoaded = false;
        
                        } else {
                            this.userPointsInfo = result;
                            this.isLoaded = false;
                        }
        
                    }).catch(error => {
                        this.error = error;
                        this.reduceErrors(error);
                        this.showToast(this.errorHeader, this.errorMessageToDisplay, 'error');
                        this.isLoaded = false;
                    })*/

                }

            } else {
                this.isLoaded = false;
            }
        }
    }

    async checkOtp() {

        this.errorMessageToDisplay = '';

        this.isLoaded = true;
        console.log('redeemPointsAPI');

        let otpTarget = await this.template.querySelector('[data-id="otp"]');

        if (this.otp == null || this.otp == '') {
            otpTarget.setCustomValidity('Complete this field.');
        } else {
            otpTarget.setCustomValidity('');
        }
        otpTarget.reportValidity();


        if (this.otp != null && this.otp != '') {
            await redeemPointsAPI({ membershipNumber: this.membershipNumber, token: this.token, trxId: this.otpResponse.transaction_id, otp: this.otp, amount: this.amount, mode: this.mode, conceptId: this.caseRecord.Unit__r.Project__r.ConceptId__c }).then(result => {
                console.log(JSON.stringify(result));

                if (result.redemption_id == null) {
                    this.errorMessageToDisplay = result.message;
                    this.errorHeader = 'Redeem Points';
                    this.isLoaded = false;

                } else {
                    this.redeemPointsResponse = result;

                    if (this.token == '') {

                        getAccessTokenAPI().then(result => {

                            this.token = result;

                            getUserPointsAPI({ membershipNumber: this.membershipNumber, token: this.token }).then(result => {

                                this.userPointsInfo = result;
                                console.log('After Redeem: ' + this.userPointsInfo);

                                let remarks = 'Darna Points. \nRedemption against (Installment/LPC): ' + this.redemptionAgainst + '\nPoints Redeemed: ' + this.redeemPointsResponse.points + '\nAvailable Points After Redeemption: ' + this.userPointsInfo.available_points + '\nAvailable Amount After Redeemption: ' + this.userPointsInfo.amount + ' ' + this.userPointsInfo.amountCurrency;

                                createReceiptAcknowledgementForRedemption({
                                    caseRecord: this.caseRecord, paymentType: 'Credit Note', amount: this.redeemPointsResponse.amount, referenceNumber: this.redeemPointsResponse.redemption_id,
                                    receiptNumber: this.redeemPointsResponse.redemption_reference_code, remarks: remarks, response: this.redeemPointsResponse
                                }).then(result => {

                                    this.updateRecordView(this.recordId);
                                    console.log(JSON.stringify(result));
                                    this.showToast('Success', 'Points has been redeemed successfully', 'success');

                                }).catch(error => {
                                    this.error = error;
                                    this.reduceErrors(error);
                                    this.showToast(this.errorHeader, this.errorMessageToDisplay, 'error');
                                    this.isLoaded = false;
                                })

                            }).catch(error => {
                                this.error = error;
                                this.reduceErrors(error);
                                this.showToast(this.errorHeader, this.errorMessageToDisplay, 'error');
                                this.isLoaded = false;
                            })

                        }).catch(error => {
                            this.error = error;
                            this.reduceErrors(error);
                            this.showToast(this.errorHeader, this.errorMessageToDisplay, 'error');
                            this.isLoaded = false;
                        })
                    } else {
                        getUserPointsAPI({ membershipNumber: this.membershipNumber, token: this.token }).then(result => {


                            this.userPointsInfo = result;
                            console.log('After Redeem: ' + this.userPointsInfo);

                            let remarks = 'Darna Points. \nRedemption against (Installment/LPC): ' + this.redemptionAgainst + '\nPoints Redeemed: ' + this.redeemPointsResponse.points + '\nAvailable Points After Redeemption: ' + this.userPointsInfo.available_points + '\nAvailable Amount After Redeemption: ' + this.userPointsInfo.amount + ' ' + this.userPointsInfo.amountCurrency;

                            createReceiptAcknowledgementForRedemption({
                                caseRecord: this.caseRecord, paymentType: 'Credit Note', amount: this.redeemPointsResponse.amount, referenceNumber: this.redeemPointsResponse.redemption_id,
                                receiptNumber: this.redeemPointsResponse.redemption_reference_code, remarks: remarks, response: this.redeemPointsResponse
                            }).then(result => {

                                this.updateRecordView(this.recordId);
                                console.log(JSON.stringify(result));
                                this.showToast('Success', 'Points has been redeemed successfully', 'success');

                            }).catch(error => {
                                this.error = error;
                                this.reduceErrors(error);
                                this.showToast(this.errorHeader, this.errorMessageToDisplay, 'error');
                                this.isLoaded = false;
                            })


                        }).catch(error => {
                            this.error = error;
                            this.reduceErrors(error);
                            this.showToast(this.errorHeader, this.errorMessageToDisplay, 'error');
                            this.isLoaded = false;
                        })
                    }
                }

            }).catch(error => {
                this.error = error;
                this.reduceErrors(error);
                this.showToast(this.errorHeader, this.errorMessageToDisplay, 'error');
                this.isLoaded = false;
            })
        } else {
            this.isLoaded = false;
        }
    }

    handleSOAClick(event) {

        if (this.caseRecord.SalesOrder__c == null) {
            this.errorMessageToDisplay = 'Kindly populate Sales Order to see Statment of Account';
            this.errorHeader = 'Statment of Account';
            this.isLoaded = false;

        } else {

            var mainUrl = getVFDomainURL();
            var fullUrl = mainUrl + '/apex/StatementOfAccountDocument?id=' + this.caseRecord.SalesOrder__c;
            console.log('Page URL - ' + fullUrl);
            this[NavigationMixin.GenerateUrl]({
                type: 'standard__webPage',
                attributes: {
                    url: '/apex/StatementOfAccountDocument?id=' + this.caseRecord.SalesOrder__c
                }
            }).then(url => { window.open(url) });
        }
    }

    navigateToSR() {

        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Case',
                actionName: 'view'
            }
        }).then((url) => {
            window.location.replace(url);
        });
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant

        });
        this.dispatchEvent(event);
    }

    reduceErrors(errors) {

        if (this.error.body) {
            if (Array.isArray(this.error.body)) {
                this.errorMessageToDisplay += this.error.body.map(e => e.message).join(', ');
            }
            else if (typeof this.error.body === 'object') {
                let fieldErrors = this.error.body.fieldErrors;
                let pageErrors = this.error.body.pageErrors;
                let duplicateResults = this.error.body.duplicateResults;
                let exceptionError = this.error.body.message;

                if (exceptionError && typeof exceptionError === 'string') {
                    this.errorMessageToDisplay += exceptionError;
                }

                if (fieldErrors) {
                    for (var fieldName in fieldErrors) {
                        let errorList = fieldErrors[fieldName];
                        for (var i = 0; i < errorList.length; i++) {
                            this.errorMessageToDisplay += fieldName + ' ' + errorList[i].message + ' ';
                            this.errorHeader = pageErrors[i] != null ? pageErrors[i].statusCode : this.errorHeader;
                        }
                    }
                }

                if (pageErrors && pageErrors.length > 0) {
                    for (let i = 0; i < pageErrors.length; i++) {
                        this.errorMessageToDisplay += pageErrors[i].message;
                        this.errorHeader = pageErrors[i] != null ? pageErrors[i].statusCode : this.errorHeader;
                    }
                }

                if (duplicateResults && duplicateResults.length > 0) {
                    this.errorMessageToDisplay += 'duplicate result error';
                }
            }
        }
        // handles errors from the lightning record edit form
        if (this.error.message) {
            this.errorMessageToDisplay += this.error.message;
        }
        if (this.error.detail) {
            this.errorMessageToDisplay += this.error.detail;
        }

    }
}