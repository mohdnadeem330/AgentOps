import { LightningElement, api, track } from 'lwc';
import Images from "@salesforce/resourceUrl/RETLTenantPortalImages16";
import getAllServiceData from '@salesforce/apex/RETL_ServiceRequestWizardController.getAllServiceData';
export default class RetlTenantServiceSelector extends LightningElement {
    houseimage = Images + '/Request/house.png';
    userImage = Images + '/Request/user.png';
    settingsImage = Images + '/Request/settings.png';
    defaultImage = Images + '/Request/default.png';
    icon1image = Images + '/Request/icon1.png';
    icon2image = Images + '/Request/icon2.png';
    icon11image = Images + '/Request/icon11.png';
    icon12image = Images + '/Request/icon12.png';
    icon13image = Images + '/Request/icon13.png';
    icon14image = Images + '/Request/icon14.png';
    icon15image = Images + '/Request/icon15.png';
    icone18image = Images + '/Request/icon18.png';
    icon10image = Images + '/Request/icon10.png';
    leaseImage = Images + '/Request/icon24.png';
    complimentImage = Images + '/Request/compliments.png';

    @api orderId;
    @api contactId;
    @api storeName;
    @api accessToken;
    @api profileName
    @api userData
    @api requestSubmittingBy
    @track categories = [];
    @track subCategories = [];
    @track serviceTypes = [];
    @track serviceTypeOptionsGeneral = [];
    @track savedFilesBySection = {}
    @track savedFilesByContractor = {}
    @track formData = {};
    selectedCategory;
    selectedSubCategory;
    selectedServiceType;
    progressValue = 20;
    currentStep = 1;
    totalSteps = 5
    serviceMap = {};
    stepContent = 'Select a type of request';
    dynamicButtonLabel = 'Next'
    showButton = false;
    showFields = false;
    isShow = true;
    isLoading = true;
    isCaseCreated = false;
    isGeneral = false;
    caseComments
    caseNumber
    caseId
    showTermsLink = false;
    showTerms = false;
    errorText
    subject;
    description;
    additional = '';
    selectedEnquiryCategory = '';
    selectedEnquirySubCategory = '';
    isLeaseAmendment = false;
    //showSubCategory = true;
    persona;
    connectedCallback() {
        if (this.profileName === 'Retail Contractor Profile' || this.profileName === 'DM Requestor Partner Login') {
            this.persona = 'Contractor';
        }
        else{
             this.persona = 'Tenant';
             //this.userData = ''
        }
        getAllServiceData({ persona: this.persona }).then(data => {
            this.buildMap(data);
        });
        console.log('this.userData',JSON.stringify(this.userData));
    }

    showSpinner() {
        this.isLoading = true;
        setTimeout(() => {
            this.isLoading = false;
        }, 3000);
    }

    buildMap(data) {
        let map = {};
        data.forEach(sr => {
            // if (sr.RETL_Persona__c.includes(this.persona)) {
            let category = sr.RETL_Category__c;
            let subCategory = sr.RETL_Sub_Category__c;
            let serviceType = sr.RETL_Service_Type__c;
            if (!map[category]) {
                map[category] = {
                    subCategories: {},
                    totalSteps: sr.RETL_Total_Steps__c,
                    stepContent: sr.RETL_Next_Step_Title__c
                };
            }
            if (subCategory) {
                if (!map[category].subCategories[subCategory]) {
                    map[category].subCategories[subCategory] = {
                        serviceTypes: [],
                        totalSteps: sr.RETL_Total_Steps__c,
                        stepContent: sr.RETL_Next_Step_Title__c
                    };
                }
                if (serviceType) {
                    map[category].subCategories[subCategory].serviceTypes.push({
                        id: sr.Id,
                        label: serviceType,
                        totalSteps: sr.RETL_Total_Steps__c,
                        stepContent: sr.RETL_Next_Step_Title__c,
                        content: sr.RETL_Content__c
                    });
                }
            }
            // }
        });
        this.serviceMap = map;
        this.categories = Object.keys(map).map(cat => ({
            label: cat,
            value: cat,
            totalSteps: map[cat].totalSteps,
            stepContent: map[cat].stepContent,
            ...this.buildIconData(cat)
        }));
        this.isLoading = false;
    }

    // --- Getters for screen visibility ---
    get showCategoryORGeneralServiceType() {
        return this.currentStep === 1 ? true : this.currentStep === 2 && this.selectedCategory === 'General Request' ? true : false;
    }

    get options() {
        return this.currentStep === 1 ? this.categories : this.serviceTypeOptionsGeneral;
    }
    get showSubCategory() {
        if (this.selectedCategory !== 'Lease Amendment') {
            return this.currentStep === 2 && (this.selectedCategory !== 'General Request' && this.selectedCategory !== 'Lease Amendment');
        }
        return '';
    }



    get showServiceTypes() {
        return (this.currentStep === 2 && this.selectedCategory === 'Lease Amendment') || this.currentStep === 3 && this.selectedCategory !== 'General Request' && this.selectedCategory !== 'Lease Amendment';
    }

    get conditionalFiltering() {
        // Hide if General Request + step 2, otherwise show
        return !(this.selectedCategory === 'General Request' && this.currentStep === 2) || this.showFields;
    }

    get headTitle() {
        if (this.selectedCategory !== 'General Request') return 'Select a service';
        if (this.selectedCategory === 'General Request') return 'Select from general services';
    }

    get rightContent() {
        if (this.selectedCategory === 'NOC') {
            return 'I need to request for an'
        }
        if (this.selectedCategory === 'Work Permit') {
            return 'I need to request for a'
        }
        if (this.selectedCategory === 'Lease Amendment') {
            return 'I need help with my'
        }
        if (this.selectedCategory === 'General Request' && this.selectedServiceType === 'Enquiry') {
            return 'I need help with my'
        }
        else if (this.selectedCategory === 'General Request' && this.selectedServiceType !== 'Enquiry') {
            return 'I want to send a'
        }
    }

    get serviceTypeStyle() {
        return this.selectedCategory === 'General Request'
            ? 'service-name'
            : 'service-name2';
    }

    handleLeftForEnquiry(event) {
        this.additional = 'regarding';
        if( event.detail.fieldName === 'RETL_SR_Category__c'){
            this.selectedEnquiryCategory = event.detail.value ;
            this.selectedEnquirySubCategory  = '';
        }
        if( event.detail.fieldName === 'RETL_SR_Sub_Category__c'){
            this.selectedEnquirySubCategory = 'for ' + event.detail.value;
        }
        //event.detail.fieldName === 'RETL_SR_Category__c' ? event.detail.value : this.selectedEnquiryCategory;
        //this.selectedEnquirySubCategory = event.detail.fieldName === 'RETL_SR_Sub_Category__c' ? 'for ' + event.detail.value : this.selectedEnquirySubCategory;
    }

    // For left text heading
    get selectedCategoryLabel() {
        if (this.selectedCategory === 'NOC') return 'NOC';
        if (this.selectedCategory === 'Work Permit') return 'Work Permit';
        if (this.selectedCategory === 'General Request') return '';
        return this.selectedCategory;
    }

    handleNext(event) {
        // Run validations first
        if (!this.validateStep(event)) {
            //  this.scrollToElement('.error-text', 120);
            return;
        }
        console.log('validation passed')
        const label = event.target.label;
        if (label === 'Submit') {
            const child = this.template.querySelector('c-retl-_-tenant-service-request-field-mapping');
            if (child) {
                child.submitCallFromParent();
            }
            this.isLoading = true;
            return;
        }
        // Clear errors if everything is valid
        this.errorText = '';
        this.scrollToElement('.forms-container', 120);
        if (this.currentStep === 2 && this.selectedCategory === 'Lease Amendment') {
            this.showFields = true;
        }
        // Move forward
        this.nextStep();
        if (this.currentStep === this.totalSteps) {
            this.dynamicButtonLabel = 'Submit';
            this.showTermsLink = true;
        }
        if (this.currentStep >= 2 && this.selectedCategory !== 'General Request') {
            this.showButton = true;
        }
        else if (this.currentStep >= 3 && this.selectedCategory === 'General Request') {
            this.showButton = true;
        }
        const subCat = this.serviceMap[this.selectedCategory]?.subCategories[this.selectedSubCategory];
        if (subCat) {
            if (!this.selectedServiceType) {
                this.stepContent = subCat.stepContent;
            } else {
                const svc = subCat.serviceTypes.find(st => st.label === this.selectedServiceType);
                this.stepContent = svc ? svc.stepContent : '';
            }
        }

        if (this.currentStep > 3 && this.selectedCategory !== 'General Request') {
            this.showFields = true;
        }
        console.log('this.selectedSubCategory next step',this.selectedSubCategory);
    }

    validateStep(event) {
        // Step 2: Need to pick a subcategory for NOC/Work Permit
        if (this.currentStep === 2 && ((this.selectedCategory !== 'General Request' && this.selectedCategory !== 'Lease Amendment' && !this.selectedSubCategory) || (this.selectedCategory === 'Lease Amendment' && !this.selectedServiceType))) {
            if (this.selectedCategory === 'NOC') {
                this.errorText = 'Select type of NOC Request';
            } else if (this.selectedCategory === 'Work Permit') {
                this.errorText = 'Select type of Work Permit';
            } else {
                this.errorText = 'Please make a selection';
            }
            return false;
        }
        let isValid = true;
        if (this.currentStep >= 4 && this.selectedCategory !== 'General Request') {
            const child = this.template.querySelector('c-retl-_-tenant-service-request-field-mapping');
            if (child) {
                isValid = child.handleNext(event);
            }

        }
        else if (this.currentStep >= 3 && (this.selectedCategory === 'General Request' || this.selectedCategory === 'Lease Amendment' )) {

            const child = this.template.querySelector('c-retl-_-tenant-service-request-field-mapping');
            if (child) {
                isValid = child.handleNext(event);
            }

        }
        if (!isValid) {
            console.error('Validation failed, staying on current step');
            return; // stop, don’t move forward
        }
        // Step 3: Need to pick a service type for the selected subcategory
        if (this.currentStep === 3 && !this.selectedServiceType) {
            this.errorText = 'Select type of ' + this.selectedSubCategory;
            return false;
        }
        if(this.currentStep === 3 && this.selectedCategory === 'General Request' && this.selectedServiceType === 'Enquiry' ){
                if( !this.selectedEnquiryCategory ){
                   return false;
                }
                else if(!this.selectedEnquirySubCategory ){
                    return false;
                }
         }
        return true; // Passed validation
    }

    // --- Navigation ---
    nextStep() {
        this.currentStep++;
    }

    // --- Back Button ---
    handleBackClick() {
        if (this.currentStep === 1) {
            this.topCloseBack();

        }
        this.previousStep();
        // reset state depending on where we landed
        if (this.currentStep === 1) {
            this.selectedCategory = null;
            this.selectedSubCategory = null;
            this.showSubCategoryLabel = false;
            this.selectedServiceType = null;
            this.subCategories = [];
            this.serviceTypes = [];
            this.serviceTypeOptionsGeneral = [];
            this.stepContent = 'Select a type of request';
            this.showButton = false;
        } else if (this.currentStep === 2) {
            this.additional = '';
            if (this.selectedCategory === 'General Request') {
                this.showButton = false;
                this.selectedEnquirySubCategory ='';
                this.selectedEnquiryCategory = ''
                //this.selectedCategory = null;
                //this.serviceTypeOptionsGeneral = [];
                this.stepContent = this.serviceMap['General Request']?.stepContent || 'Select a general service';
            }
            else if( this.selectedCategory === 'Lease Amendment'){
                this.showSubCategoryLabel = false;
            }else {
                this.selectedServiceType = null;
                //this.serviceTypes = [];
                this.stepContent = this.serviceMap[this.selectedCategory]?.stepContent || 'Select a sub-category';
            }
        }
        else if (this.currentStep === 3) {
            // Going back from service type → show subcategory content
            if (this.selectedCategory && this.selectedSubCategory) {
                this.stepContent = this.serviceMap[this.selectedCategory].subCategories[this.selectedSubCategory].stepContent;
            }
        }
        if (this.currentStep < 4 && this.selectedCategory !== 'General Request') {
            this.showFields = false;
        }
        else if (this.currentStep < 3 && this.selectedCategory === 'General Request' || this.selectedCategory === 'Lease Amendment') {
            this.showFields = false;
        }
    }

    previousStep() {
        if (this.currentStep > 1) {
            this.currentStep--;
        }
        this.dynamicButtonLabel = 'Next';
        this.showTermsLink = false;
    }

    topCloseBack() {
        console.log('topCloseBack');

        this.dispatchEvent(new CustomEvent('back', { bubbles: true, composed: true }));
    }

    // --- Progress calculation ---
    get progressPercent() {
        if (!this.totalSteps) return 0;
        return Math.floor((this.currentStep / this.totalSteps) * 100);
    }

    get progressStyle() {
        return `background-color:#eb6924; width:${this.progressPercent}%; height:5px;`;
    }

    handleStepTitleFromChild(event) {
        this.stepContent = event.detail;
    }

    // --- Handlers ---
    handleOptionClick(event) {
        if (this.currentStep === 1) {
            this.handleCategorySelect(event);
        }
        else {
            this.handleServiceTypeSelect(event);
        }
    }

    handleCategorySelect(event) {
        this.selectedCategory = event.currentTarget.dataset.value;
        console.log('this.selectedCategory handleCategorySelect', this.selectedCategory);
        this.totalSteps = this.serviceMap[this.selectedCategory].totalSteps;
        this.stepContent = this.serviceMap[this.selectedCategory].stepContent;
        this.isLeaseAmendment = false;
        //this.showSubCategory = true;
        if (this.selectedCategory === 'General Request') {
            // General skips subcategories → go to step 2
            this.isGeneral = true;
            this.subCategories = null;

            this.serviceTypeOptionsGeneral =
                this.serviceMap[this.selectedCategory].subCategories['General'].serviceTypes
                    .map(st => ({
                        label: st.label,
                        value: st.label,
                        content: st.content,
                        iconName: this.iconFor(st.label)
                    }));
            this.currentStep = 2;
        }
        else if (this.selectedCategory === 'Lease Amendment') {
            //this.showSubCategory = false;
            this.isLeaseAmendment = true;
            this.additional = ' regarding ';
            this.serviceTypes = this.serviceMap[this.selectedCategory].subCategories['Amendment Request'].serviceTypes;
            this.errorText = '';
            this.currentStep = 2;
            this.isGeneral = false;
            this.showButton = true;
        }
        else {
            console.log('else');
            this.showButton = true;
            this.subCategories = Object.keys(this.serviceMap[this.selectedCategory].subCategories)
                .map(sc => ({
                    label: sc,
                    value: sc,
                    content: sc.content,
                }));
            this.currentStep = 2;
            this.isGeneral = false;
        }

        //lease amendment

    }

    // highlight selected subcategory
    get subCategoriesWithClasses() {
        return this.subCategories.map(s => {
            const base = 'slds-button pill2 text-aligner slds-button_neutral';
            const active = this.selectedSubCategory === s.value ? ' pill2-active' : '';
            return { ...s, cssClass: base + active };
        });
    }

    // highlight selected service type
    get serviceTypesWithClasses() {
        return this.serviceTypes.map(s => {
            const base = 'slds-button pill2 text-aligner slds-button_neutral';
            const active = this.selectedServiceType === s.label ? ' pill2-active' : '';
            return { ...s, cssClass: base + active };
        });
    }
    showSubCategoryLabel = false;
    handleSubCategorySelect(event) {
        this.selectedSubCategory = event.currentTarget.dataset.value;
        this.showSubCategoryLabel = true;
        this.totalSteps = this.serviceMap[this.selectedCategory].subCategories[this.selectedSubCategory].totalSteps;
        this.serviceTypes = this.serviceMap[this.selectedCategory].subCategories[this.selectedSubCategory].serviceTypes;
        this.errorText = '';
    }

    handleServiceTypeSelect(event) {
        this.selectedServiceType = event.currentTarget.dataset.value;
        this.errorText = '';
        this.formData = {};
        let subCategories = this.selectedCategory === 'General Request' ? 'General' : this.selectedCategory === 'Lease Amendment' ? 'Amendment Request' : this.selectedSubCategory;
        if (this.selectedCategory === 'Lease Amendment') {
            this.selectedSubCategory = 'Amendment Request';
        }
        const serviceTypes =
            this.serviceMap[this.selectedCategory]
                .subCategories[subCategories]
                .serviceTypes;

        const selectedService = serviceTypes.find(
            st => st.label === this.selectedServiceType // or st.id if you stored id
        );
        if (selectedService) {
            this.totalSteps = selectedService.totalSteps;
            console.log('this.totalSteps', this.totalSteps);
        } else {
            console.error('Selected service type not found:', this.selectedServiceType);
        }
        if (this.selectedCategory === 'General Request') {
            console.log('this.selectedCategory ')
            this.selectedSubCategory = '';
            this.showFields = true;
            this.showButton = true;
            this.nextStep();
            if (this.totalSteps === this.currentStep) {
                this.showTermsLink = true;
                this.dynamicButtonLabel = 'Submit'
            }
        }
        if (this.selectedCategory !== 'General Request') {

            const container = this.template.querySelector('.content');
            if (container) {
                container.innerHTML = event.currentTarget.dataset.content; // data = HTML string from custom field
                const ul = container.querySelector('ul');
                if (ul) {
                    ul.classList.add('two-column-list');
                }
            }
            this.scrollToElement('.forms-container', 120);
        }
    }

    scrollToElement(selector, offset = 80) {
        const el = this.template.querySelector(selector);
        if (el) {
            const y = el.getBoundingClientRect().top + window.pageYOffset - offset;
            window.scrollTo({ top: y, behavior: 'smooth' });
        }
    }

    // Helpers
    buildIconData(type) {
        return { iconName: this.iconFor(type), iconNameIsUrl: true };
    }

    iconFor(type) {
        switch (type) {
            case 'NOC': return this.houseimage;
            case 'Work Permit': return this.userImage;
            case 'General Request': return this.settingsImage;
            case 'Enquiry': return this.icon12image;
            case 'Service Request': return this.icon12image;
            case 'Complaint': return this.icon13image;
            case 'Feedback': return this.icon14image;
            case 'Compliment': return this.complimentImage;
            case 'Others': return this.icon15image;
            case 'Lease Amendment':return this.leaseImage;
            default: return this.defaultImage;
        }
    }

    handleCaseCreated(event) {
        this.isShow = false;
        this.isLoading = false;
        this.showButton = false;
        this.isCaseCreated = true;
        this.caseComments = event.detail.caseComments;
        this.caseNumber = event.detail.caseNumber;
        this.caseId = event.detail.caseId;
        this.subject = event.detail.subject;
        this.description = event.detail.description;
    }

    content = '<p>The use of this website is subjected to the following terms of use.</p> <ul > <li>The content of the pages of this website is for your general information...</li> <li>Your use of any information or materials on this website is entirely at your own risk...</li> <li>This website contains material which is owned by or licensed to us...</li> <li>All trademarks reproduced in this website...</li> <li>From time to time this website may also include links to other websites...</li> <li>Your use of this website and any dispute arising out of such use...</li> </ul>'
    handleTermsClick() {
        const child = this.template.querySelector('c-retl-_-tenant-service-request-field-mapping');
        this.showTerms = true;
        this.isShow = false;
    }

    handleTermsClose() {
        this.showTerms = false;
        this.isShow = true;
    }

    handleFormChange(event) {
        // Merge child updates into parent's formData
        this.formData = { ...this.formData, ...event.detail };
    }

    handleFilesChange(event) {
        this.savedFilesBySection = event.detail.savedFilesBySection;
        this.savedFilesByContractor = event.detail.savedFilesByContractor;
    }

}