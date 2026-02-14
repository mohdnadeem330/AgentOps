import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { getPicklistValues, getObjectInfo} from 'lightning/uiObjectInfoApi';
import HOMEFINANCE_IMAGES from '@salesforce/resourceUrl/HomeFinanceImages';
import CASE_OBJECT from '@salesforce/schema/Case';
import MOBILE_COUNTRYCODE_FIELD from '@salesforce/schema/Case.MobileCountryCode__c';
import EMPLOYMENT_STATUS_FIELD from '@salesforce/schema/Case.HF_EmploymentStatus__c';
import PROPERTY_TYPE_FIELD from '@salesforce/schema/Case.HF_Property_type__c';
import NATIONALITY_FIELD from '@salesforce/schema/Case.HF_Nationality__c';
import RESIDENCE_FIELD from '@salesforce/schema/Case.HF_Residency__c';
import createHFCase from '@salesforce/apex/ManageRequestController.createHomeFinanceCase';
import getValidateEmail from '@salesforce/apex/EmailValidation.getValidateEmailWithAura';
import getValidatePhoneNoWithAura from '@salesforce/apex/PhoneNoValidation.getValidatePhoneNoWithAura';

const DELAY = 4000;
export default class CreateHomeFinanceCase extends LightningElement
{
    //@wire(getValidateEmail, { email: '$emailaddress' })
    //emailResponse;

    @wire(getValidatePhoneNoWithAura, { phoneNo: '$mobileNumberToCheck' })
    mobileResponse;

    @api recordId;
    @api emailaddress;
    @api mobileNumberToCheck;
    pic1                        = HOMEFINANCE_IMAGES + "/HomeFinanceImages/buildings/image1.jpg";
    pic2                        = HOMEFINANCE_IMAGES + "/HomeFinanceImages/buildings/image2.jpg";
    pic3                        = HOMEFINANCE_IMAGES + "/HomeFinanceImages/buildings/image3.jpg";
    isLoading                   = false;
    mobCountryCodeOptions;
    emplStatusOptions;
    propertyTypeOptions;
    nationalityOptions;
    residenceOptions;

    firstname; lastname; countrycode; nationality; mobileNumber; residence; city;
    employmentStatus; propertytype; approxpropvalue; approxloanamt; comments;

    @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
    caseObjectInfo;

    @wire(getPicklistValues, {
        recordTypeId: "$caseObjectInfo.data.defaultRecordTypeId",
        fieldApiName: MOBILE_COUNTRYCODE_FIELD
    })
    mobCountryCode({error, data}) {
        if (error) {
        } else if (data) {
            this.mobCountryCodeOptions = data.values;
        }
    }

    @wire(getPicklistValues, {
        recordTypeId: "$caseObjectInfo.data.defaultRecordTypeId",
        fieldApiName: EMPLOYMENT_STATUS_FIELD
    })
    emplStatus({error, data}) {
        if (error) {
        } else if (data) {
            this.emplStatusOptions = data.values;
        }
    }

    @wire(getPicklistValues, {
        recordTypeId: "$caseObjectInfo.data.defaultRecordTypeId",
        fieldApiName: PROPERTY_TYPE_FIELD
    })
    propertyType({error, data}) {
        if (error) {
        } else if (data) {
            this.propertyTypeOptions = data.values;
        }
    }

    @wire(getPicklistValues, {
        recordTypeId: "$caseObjectInfo.data.defaultRecordTypeId",
        fieldApiName: NATIONALITY_FIELD
    })
    nationality({error, data}) {
        if (error) {
        } else if (data) {
            this.nationalityOptions = data.values;
        }
    }
    
    @wire(getPicklistValues, {
        recordTypeId: "$caseObjectInfo.data.defaultRecordTypeId",
        fieldApiName: RESIDENCE_FIELD
    })
    residency({error, data}) {
        if (error) {
        } else if (data) {
            this.residenceOptions = data.values;
        }
    }
    
    async handleChangeFields(event)
    {
        var value = event.target.value;

        if (event.target.name == 'firstName') {
            this.firstname = value;
        }
        if (event.target.name == 'lastName') {
            this.lastname = value;
        }
        if (event.target.name == 'countryCode') {
            this.countrycode = value;
        }
        if (event.target.name == 'mobileNumber') {
            this.mobileNumber = value;

            /*
            this.mobileNumberToCheck = this.countrycode + this.mobileNumber;
            this.delayTimeout = setTimeout(async () => {
                let target = await this.template.querySelector('[data-id="mobileNumber"]');
                if (!this.mobileResponse.data) {
                    target.setCustomValidity("Please Enter Valid Mobile Number.")
                } else {
                    target.setCustomValidity("");
                }
                target.reportValidity();
            }, DELAY);
            */
        }
        if (event.target.name == 'emailaddress') {
            this.emailaddress = value;
        }
        if (event.target.name == 'nationality') {
            this.nationality = value;
        }
        if (event.target.name == 'residence') {
            this.residence = value;
        }
        if (event.target.name == 'city') {
            this.city = value;
        }
        if (event.target.name == 'employmentStatus') {
            this.employmentStatus = value;
        }
        if (event.target.name == 'propertyType') {
            this.propertytype = value;
        }
        if (event.target.name == 'approxPropValue') {
            this.approxpropvalue = value;
        }
        if (event.target.name == 'approxLoanAmount') {
            this.approxloanamt = value;
        }
        if (event.target.name == 'Comments') {
            this.comments = value;
        }
        
    }

    handleMobileNumberBlur(event)
    {
        let enteredMobNumber    = event.target.value;
        if(enteredMobNumber != ''){
            let mob                 = enteredMobNumber.replace(/[^0-9]/g,'');
            let mobNumber           = parseInt(mob);
            this.mobileNumber       = mobNumber.toString();
        }

        this.mobileNumberToCheck = this.countrycode + this.mobileNumber;
            this.delayTimeout = setTimeout(async () => {
                let target = await this.template.querySelector('[data-id="mobileNumber"]');
                if (!this.mobileResponse.data) {
                    target.setCustomValidity("Please Enter Valid Mobile Number.")
                } else {
                    target.setCustomValidity("");
                }
                target.reportValidity();
            }, DELAY);
    }

    async handleEmailBlur(event)
    {
        let emailAdd = event.target.value;
        let target = await this.template.querySelector('[data-id="emailaddress"]');
        await getValidateEmail({
            email : emailAdd
        }).then(result => {
            // TODO On success
            if (!result) {
                target.setCustomValidity("Please Enter Valid Email");
            } else {
                target.setCustomValidity("");
            }
            target.reportValidity();
        }).catch(error =>{
            console.log(error);
        });
            
    }

    async handleSubmit(event)
    {
        console.log('handle Submit' +event);
        this.isLoading = true;

        const isInputsCorrect = await [...this.template.querySelectorAll('lightning-input'), ...this.template.querySelectorAll('lightning-combobox')]
        .reduce((validSoFar, inputField) => {
            inputField.reportValidity();
            return validSoFar && inputField.checkValidity();
        }, true);

        if (isInputsCorrect)
        {
            console.log('All Success Validations');

            var createCase = {
                'sobjectType'               : 'Case',
                'Subject'                   : 'HomeFinance case',
                'SubVertical__c'            : 'Home Finance',
                'Category__c'               : 'Home Finance',
                'Description'               : this.comments,
                'Status'                    : 'New',
                'Origin'                    : 'Broker Portal',
                
                'HF_FirstName__c'           : this.firstname,
                'HF_LastName__c'            : this.lastname,
                'MobileCountryCode__c'      : this.countrycode,
                'MobileNumber__c'           : this.mobileNumber,
                'Email__c'                  : this.emailaddress,
                'HF_Nationality__c'         : this.nationality,
                'HF_Residency__c'           : this.residence,
                'HF_City__c'                : this.city,
                'HF_EmploymentStatus__c'    : this.employmentStatus,
                'HF_Property_type__c'       : this.propertytype,
                'HF_ApproximatePropertyValue__c'        : this.approxpropvalue,
                'HF_ApproximateLoanAmountRequired__c'   : this.approxloanamt,
                
            }

            await createHFCase({
                caseRecord : createCase
            }).then(result => {
                // TODO On success
                console.log(result);
                this.showToast('Success', 'Case Successfully Created with Reference Number:'+result, 'success');
                this.isLoading = false;
                this.resetFormAction();
            }).catch(error => {
                // TODO Error handling
                this.isLoading = false;
                console.log(JSON.stringify(error));
                if (error.body.pageErrors[0].message && error.body.pageErrors[0].message != null){
                    this.showToast('Error', JSON.stringify(error.body.pageErrors[0].message), 'error');
                }else{
                    this.showToast('Error', 'Some Error Occured', 'error');
                }
            });

        }else{
            this.isLoading = false;
        }
    }

    showToast(title, message, variant)
    {
        const event = new ShowToastEvent({
            title:      title,
            message:    message,
            variant:    variant,
            mode:       'sticky'
        });
        this.dispatchEvent(event);
    }

    handleFieldsReset(event)
    {
        console.log('handle Cancel', event);
        //this.isLoading = false;
        this.template.querySelector('form').reset();
    }

    handleError(event)
    {
        this.isLoading = false;

        console.log('Error - ', event.detail.detail );
        const evt = new ShowToastEvent({
            title: 'Error',
            message: event.detail.detail,
            variant: 'error',
            mode: 'sticky'
        });
        this.dispatchEvent(evt);
        
    }

    resetFormAction()
    {
        this.firstname      = '';
        this.lastname       = '';
        this.countrycode    = '';
        this.mobileNumber   = '';
        this.emailaddress   = '';
        this.nationality    = '';
        this.residence      = '';
        this.city           = '';
        this.employmentStatus= '';
        this.propertytype   = '';
        this.approxpropvalue= '';
        this.approxloanamt  = '';
        this.comments       = '';
    }


}