import { api, LightningElement, track, wire } from 'lwc';
import getOtpDetails from '@salesforce/apex/BrokerAgencyRegistrationController.getOtpDetails';
import getOtpRecord from '@salesforce/apex/BrokerAgencyRegistrationController.getOtpRecord';
import getAllConstants from '@salesforce/apex/BrokerAgencyRegistrationController.getAllConstants';
import updateServiceRequestRecordStatus from '@salesforce/apex/BrokerAgencyRegistrationController.updateServiceRequestRecordStatus';
import updateAgencyTeam from '@salesforce/apex/BrokerAgencyRegistrationController.updateAgencyTeam';
import PortalLoginURL from '@salesforce/label/c.PortalLoginURL';

export default class BrokerRegistrationOTP extends LightningElement {

    userOTP;
    //serviceRequestId;
    @track success = false;
    @track isLoaded = false;
    @track otp;
    @track message = '';
    @api serviceRequestId;

    @wire(getAllConstants)
    srStatus({ error, data }) {
        if (data) {
            this.srStatus = data.SUBMITTED;
        } else {
        }
    }

    async connectedCallback() {

        await getOtpRecord({ serviceRequestId: this.serviceRequestId })
            .then(result => {

                console.log(result);
                console.log(this.serviceRequestId);

                if (result != null) {
                    if (result.HexaBPM__External_Status_Name__c != null && result.HexaBPM__External_Status_Name__c != 'Draft') {

                        this.otp = false;

                        this.message = 'This Registration was Already Completed';

                        setTimeout(() => {
                            window.location.href = PortalLoginURL;
                        }, 3000);

                    } else if (result.State__c == 'PinExpired') {

                        this.otp = true;

                        setTimeout(() => {
                            const isInputsCorrect1 = [...this.template.querySelectorAll('[data-id="OTP"]')]
                                .reduce((validSoFar, inputField) => {

                                    inputField.setCustomValidity('Pin Code Expired, Please Generate another PIN.');
                                    inputField.reportValidity();

                                    return false;
                                }, true);
                        }, 1000);
                    }else{
                        this.otp = true;
                    }
                } else {
                    this.message = 'Invalid Link, Please make sure That you are using the correct URL.'
                    this.otp = false;
                }
                console.log(this.message);
            })
            .catch(error => {
                //this.errorDetails.push('Unexpected Error: ' + JSON.stringify(error));
                this.isLoaded = !this.isLoaded;
                console.log(JSON.stringify(error));
            });
    }

    handleChange(event) {

        var value = event.target.value;
        this.userOTP = value;
    }

    async resendOTP(event) {

        this.isLoaded = !this.isLoaded;

        const isInputsCorrect1 = [...this.template.querySelectorAll('[data-id="OTP"]')]
            .reduce((validSoFar, inputField) => {

                inputField.setCustomValidity('');
                inputField.reportValidity();

                return true;
            }, true);

        await updateAgencyTeam({ serviceRequestId: this.serviceRequestId })
            .then(result => {
            })
            .catch(error => {
            });

        this.isLoaded = !this.isLoaded;
    }

    async handleOTP(event) {

        this.isLoaded = !this.isLoaded;

        await getOtpDetails({ serviceRequestId: this.serviceRequestId })
            .then(result => {


                if (result != null) {

                    const isInputsCorrect1 = [...this.template.querySelectorAll('[data-id="OTP"]')]
                        .reduce((validSoFar, inputField) => {

                            if (this.userOTP !== result.OTPNumber__c) {
                                inputField.setCustomValidity('Invalid Pin Code.');
                            } else {
                                inputField.setCustomValidity('');

                                updateServiceRequestRecordStatus({ serviceRequestId: this.serviceRequestId, status: this.srStatus })
                                    .then(result => {
                                        this.otp = false;
                                        this.success = true;

                                        setTimeout(() => {
                                            window.location.href = PortalLoginURL;
                                        }, 2000);
                                    })
                                    .catch(error => {
                                        //this.errorDetails.push('Unexpected Error: ' + JSON.stringify(error));
                                    });
                            }
                            inputField.reportValidity();

                            return validSoFar && inputField.checkValidity() && (this.userOTP === result.OTPNumber__c);
                        }, true);
                } else {
                    const isInputsCorrect1 = [...this.template.querySelectorAll('[data-id="OTP"]')]
                        .reduce((validSoFar, inputField) => {

                            inputField.setCustomValidity('Session Timeout, Please Generate another PIN.');
                            inputField.reportValidity();

                            return false;
                        }, true);
                }
                this.isLoaded = !this.isLoaded;
            })
            .catch(error => {
                //this.errorDetails.push('Unexpected Error: ' + JSON.stringify(error));
                this.isLoaded = !this.isLoaded;
            });
    }
}