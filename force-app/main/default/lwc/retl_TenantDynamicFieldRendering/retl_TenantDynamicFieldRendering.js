import { LightningElement, api, track } from 'lwc';
import Images from "@salesforce/resourceUrl/RETLTenantPortalImages";
import getSessionId from '@salesforce/apex/RETL_SRDocumentHandler.getSessionId';
import getFileUploadEndpoint from '@salesforce/apex/RETL_ServiceRequestWizardController.getFileUploadEndpoint';

export default class Retl_TenantDynamicFieldRendering extends LightningElement {
    elementsimage = Images + '/Services/elements.png';
    icon1image = Images + '/Request/icon1.png';
    icon11image = Images + '/Request/icon11.png';
    icon12image = Images + '/Request/icon12.png';
    icon13image = Images + '/Request/icon13.png';
    icon14image = Images + '/Request/icon14.png';
    icon15image = Images + '/Request/icon15.png';
    icone18image = Images + '/Request/icon18.png';
    icon10image = Images + '/Request/icon10.png';
    houseimage = Images + '/Request/house.png';
    userImage = Images + '/Request/user.png';
    settingsImage = Images + '/Request/settings.png';
    defaultImage = Images + '/Request/default.png';
    //@api field;
    @api formValues;
    @api labelMap;
    @api contractorid;
    @api pairClass;
    @api fieldNameToUnique = {};
    @api currentstepFullData = [];
    @api workStartDate;
    @api workEndDate;
    @api accessToken;
    @api fileSizeLimit;
    @api mainContractorData;
    @api isMainContractorData = false;
    @api isContractorPage = false;
    @api requestSubmittingBy;
    @api networkName;
    @api contactId;
    @track allCountries = [];
    @track filteredDropdownValues = [];
    @track fileValues = [];
    @track errorMessage = '';
    @track uploadProgress = 0;
    @track uploading = false;
    @track accountobj = new Object();
    @track Contactobj = new Object();
    @track localField = {};
    dropdownVisible = false;
    fileErrorMessage;
    patternMismatchmessage;
    // convenience getters for readability
    get isText() { return this.field.dataType === 'Text'; }
    get isPhone() { return this.field.dataType === 'Phone'; }
    get isEmail() { return this.field.dataType === 'Email'; }
    get isNumber() { return this.field.dataType === 'Number'; }
    get isDate() { return this.field.dataType === 'Date'; }
    get isTime() { return this.field.dataType === 'Time'; }
    get isDateTime() { return this.field.dataType === 'DateTime'; }
    get isCheckbox() { return this.field.dataType === 'Checkbox'; }
    get isPicklist() { return this.field.dataType === 'Picklist'; }
    get isTextArea() { return this.field.dataType === 'Text Area'; }
    get isFile() { return this.field.dataType === 'File'; }
    get isArabic() { return this.field.dataType === 'Arabic Text'; }
    get isDropdown() { return this.field.dataType === 'Dropdown'; }
    get isAddress() { return this.field.dataType === 'Address'; }
    get isArabicTextArea() { return this.field.dataType === 'Arabic Text Area'; }
    get picklistOptions() {
        if (!this.field.picklistVals) return [];
        return this.field.picklistVals.split(/[\n,;]+/).map(v => ({
            label: v.trim(),
            value: v.trim()
        }));
    }
    get pattern() {
        if (this.field.validations.includes('EmiratesPattern')) {
            this.patternMismatchmessage = "Enter a valid Emirates ID (784-YYYY-NNNNNNN-C)"
            return '^784-\\d{4}-\\d{7}-\\d{1}$';
        }
        return null;  // no pattern for other fields
    }
    get currentValue() {
        if (!this.formValues) return this.field.dataType === 'Checkbox' ? false : '';

        return this.formValues[this.field.uniqueIdentifier];
    }

    get isCountry() {
        return this.field.fieldName === 'BillingCountry';
    }

    _apiField;

    @api
    set field(value) {
        this._apiField = value;
        this.localField = JSON.parse(JSON.stringify(value)); // deep clone
        if (this.accountobj && this.accountobj[this.localField.fieldName] !== undefined && this.isMainContractorData) {
            //this.localField.isDisabled = true;
        }

        if (this.Contactobj && this.Contactobj[this.localField.fieldName] !== undefined && this.isMainContractorData) {
            //this.localField.isDisabled = true;
        }
    }

    get field() {
        return this._apiField;
    }

    connectedCallback() {
        if (this.mainContractorData && this.isMainContractorData) {
            this.accountobj = { ...this.mainContractorData.Contact.Account };
            this.Contactobj = { ...this.mainContractorData.Contact };
        }
        let defaultValue = null;

        if (this.accountobj && this.accountobj[this.localField.fieldName] !== undefined && this.isMainContractorData) {
            defaultValue = this.accountobj[this.localField.fieldName];

        }

        if (this.Contactobj && this.Contactobj[this.localField.fieldName] !== undefined && this.isMainContractorData) {
            defaultValue = this.Contactobj[this.localField.fieldName];

        }

        if (defaultValue !== null) {
            this.pushDefaultValue(defaultValue);
        }

   }


    renderedCallback() {
        if (this._categoryHighlighted) return;

        if (
            this.formValues?.[this.field.uniqueIdentifier] &&
            this.field.fieldName === 'RETL_SR_Sub_Category__c' || this.field.fieldName === 'RETL_SR_Category__c'
        ) {
            const buttons = this.template.querySelectorAll(
                `[data-unique-id="${this.field.uniqueIdentifier}"]`
            );

            buttons.forEach(btn => {
                if (btn.dataset.value === this.currentValue) {
                    btn.classList.add('pill2-active');
                }
            });

            this._categoryHighlighted = true;
        }
    }
    pushDefaultValue(value) {
        const uniqueIdentifier = this.field.uniqueIdentifier;

        // update formValues silently
        this.formValues = {
            ...this.formValues,
            [uniqueIdentifier]: value
        };

        // fire change event manually (simulate user input)
        this.sendValueToParent(this.field.fieldName, value);
    }
    handleChange(event) {
        const fieldName = this.field.fieldName;
        const tag = event.target.tagName.toLowerCase();
        const isButton = tag === 'button';
        let value;
        if (isButton && event.target.classList.contains('pill2')) {
            let isAlreadySelected = event.target.classList.contains('pill2-active');
            this.template.querySelectorAll('.pill2').forEach(btn => {
                btn.classList.remove('pill2-active');
            });
            if (!isAlreadySelected) {
                value = event.target.dataset.value;
                event.target.classList.add('pill2-active');
            }
            else {
                value = '';
            }
            this.sendValueToParent(fieldName, value);
        }
        else if (event.target.type === 'checkbox') {
            value = event.target.checked;
        } else {
            value = event.target.value;
        }

        if (fieldName === 'RETL_Start_Time__c' || fieldName === 'RETL_Start_Date__c') {
            this.workStartDate = value;
        }
        if (fieldName === 'RETL_End_Date__c') {
            this.workEndDate = value;
        }
        // Get correct target field for validation
        let targetField = this.field;
        let uniqueIdentifier = this.field.uniqueIdentifier;
        const updatedFormValues = { ...this.formValues };
        updatedFormValues[uniqueIdentifier] = value;
        this.formValues = updatedFormValues;
        //  Run validation only for this input
        let error;
        if (this.isMainContractorData && this.isContractorPage) {
            error = false;
        }
        else {
            error = this.validateField(value, targetField);
            if (error) {
                event.target.setCustomValidity(error);
            } else {
                event.target.setCustomValidity('');
            }
            event.target.reportValidity();
            this.validateAll();
        }

        //  Propagate value only if no error
        if (!error) {
            this.sendValueToParent(fieldName, value);
        }
        // If field controls visibility
        if (fieldName === 'Make_Contractor_as_Responsible_Person__c') {
            this.dispatchEvent(new CustomEvent('contractorresponsibletoggle', {
                detail: {
                    contractorId: this.contractorid, // make sure child knows which contractor it belongs to
                    fieldName,
                    value
                }
            }));
        }
    }


    sendValueToParent(fieldName, value) {
        let uniqueIdentifier = this.field.uniqueIdentifier;

        this.dispatchEvent(
            new CustomEvent('fieldchange', {
                detail: { uniqueIdentifier, fieldName, value, contractorid: this.contractorid || null },
                bubbles: true,
                composed: true
            })
        );
    }

    handleClick(value) {
        this.dispatchEvent(new CustomEvent('errorstate', {
            detail: { hasError: value ? value : true },
            bubbles: true,
            composed: true
        }));
    }





    async handleFileUpload(event) {

        const file = event.target.files[0];
        if (!file) return;
        const allowedTypes = ['pdf', 'png', 'jpg', 'jpeg', 'doc', 'docx'];
        const ext = file.name.split('.').pop().toLowerCase();
        let errorMsg = '';
        if (!allowedTypes.includes(ext)) {
            errorMsg = `Invalid file type: ${fileExt}. Allowed types are ${allowedTypes.join(', ')}`;
            const updatedField = { ...this.field, errorMessage: errorMsg };
            this.field = updatedField;
            return;
        }
        if (file.size > this.fileSizeLimit * 1024 * 1024) {
            console.warn(`File too large: 1 ${file.name}`);
            errorMsg = `${file.name} exceeds ${this.fileSizeLimit} MB size limit`;
            const updatedField = { ...this.field, errorMessage: errorMsg };
            this.field = updatedField;
            return;
        }
        this.uploading = true;
        this.uploadProgress = 0;

        try {
            const sessionId = await getSessionId();
            let token = this.accessToken ? this.accessToken : sessionId
            const baseUrl = window.location.origin; // e.g., https://yourdomain.my.salesforce.com
            let endpoint;
            if (this.requestSubmittingBy === 'InternalUser' || this.networkName !== 'Tenant Portal') {
                endpoint = baseUrl + '/services/apexrest/FileUpload';
            }
            else {
                 endpoint = await this.fetchEndpoint();
            }
            // Prepare multipart form data (metadata + file)
            const formData = new FormData();
            const fileReader = new FileReader();
            fileReader.onloadend = async () => {
                const updatedField = { ...this.field, isDisabled: true };
                this.field = updatedField;
                const fileContent = fileReader.result; // ArrayBuffer
                let progressInterval = setInterval(() => {
                    if (this.uploadProgress < 90) {
                        this.uploadProgress += Math.floor(Math.random() * 5) + 1; // +1–5% randomly
                    }

                }, 400);
                // Send file to Apex REST
                const response = await fetch(endpoint, {
                    method: 'POST',
                    headers: {
                        'Authorization': 'Bearer ' + token,
                        'Content-Type': file.type,
                        'file-name': file.name,
                        'document-type': this.field.label,
                        'submitting-by': this.requestSubmittingBy,
                        'network-name': this.networkName,
                        'contact-id': this.contactId
                    },
                    body: fileContent
                });

                if (!response.ok) {
                    throw new Error('Upload failed: ' + response.statusText);
                }

                const contentVersionId = await response.json();
                this.uploading = false;
                this.uploadProgress = 100;
                let updatedFieldvalue = { ...this.field, isDisabled: false };
                this.field = updatedFieldvalue;
                this.dispatchEvent(
                    new CustomEvent('uploadcomplete', {
                        detail: { name: file.name, contentVersionId }
                    })
                );
                this.dispatchEvent(
                    new CustomEvent('fileupload', {
                        detail: {
                            fieldName: this.field.fieldName,
                            files: [file],
                            fieldLabel: this.field.label,
                            uniqueIdentifier: this.field.uniqueIdentifier,
                            contractorid: this.contractorid,
                            contentVersionId: contentVersionId.id
                        }
                    })
                );
            };

            // Important: read as ArrayBuffer for binary upload
            fileReader.readAsArrayBuffer(file);

        } catch (err) {
            console.error('Upload error:', err);
            this.errorMessage = err.message;
            this.uploading = false;
        }
    }
    async fetchEndpoint() {
        const url = await getFileUploadEndpoint();
        return url;
    }
    get progressStyle() {
        return `width: ${this.uploadProgress}%;`;
    }



    handleFileRemove(event) {
        const index = event.currentTarget.dataset.index;
        const fieldName = event.currentTarget.dataset.field;
        const uniqueIdentifier = this.field.uniqueIdentifier;
        this.dispatchEvent(new CustomEvent('fileremove', {
            detail: { uniqueIdentifier, fieldName, index: Number(index), contractorid: this.contractorid }
        }));
    }


    //Full validity check on NEXT / SUBMIT
    @api validate() {
        // Use the current value in formValues so it also catches untouched fields
        const value = this.formValues?.[this.field.uniqueIdentifier];
        let error = this.validateField(value, this.field);
        // show or clear the message on the lightning-input
        this.showError(error);
        let valid = this.validateAll();
        error = !valid;
        console.log(' validateAll error', error)
        // return true if no error
        if (valid) {
            this.handleClick(false);
        }
        return !error;
    }

    validateAll() {
        const inputs = this.template.querySelectorAll('lightning-input, input,lightning-textarea');
        let allValid = true;
        inputs.forEach(input => {
            if (input.type !== 'file') {
                const maxLength = input.maxlength;  // comes from your dynamic fieldLimit
                const val = input.value ? input.value.trim() : '';
                if (input.required && !val) {
                    input.setCustomValidity('This field is required');
                    allValid = false;
                }
                if (maxLength && val.length > maxLength) {
                    input.setCustomValidity(`Maximum ${maxLength} characters allowed. You entered ${val.length}`);
                    allValid = false;
                }
                if (!input.reportValidity()) {
                    allValid = false;
                }
            }

        });
        return allValid;
    }

    // Display or clear the error on the lightning-input
    @api showError(msg) {
        this.errorMessage = msg || '';
        //  Apply error to all inputs (important for address fields)
        const inputs = this.template.querySelectorAll('lightning-input, lightning-textarea');
        inputs.forEach(input => {
            input.setCustomValidity(this.errorMessage);
            input.reportValidity();
        });
    }
    // All business rules in one place
    validateField(value, f) {
        console.log('validateField', JSON.stringify(f));
        if (!f) return null;  // safeguard
        const fieldName = f.fieldName || f.sfFieldName || '';
        const label = f.label || f.formLabel || f.sectionName || fieldName;
        if (f.required && (!value || value === '')) {
            return `${label} is required`;
        }
        if (!value) return null;
        for (let rule of f.validations || []) {
            if (rule === 'NoPast' && new Date(value) < this.stripTime(new Date())) {
                return `${label} cannot be in the past`;
            }
            if (rule === 'NoFuture' && new Date(value) > new Date()) {
                return `${label} cannot be in the future`;
            }
            if (rule === 'OneContractorMinimum') {
                let contractorCheck = new CustomEvent('checkcontractorinfo', {
                    detail: {},
                    bubbles: true,
                    composed: true,
                    cancelable: true // allow parent to respond
                });
                const allowed = this.dispatchEvent(contractorCheck);
                // If parent says no contractor, return error message
                if (!allowed) {
                    return `Please add minimum one contractor`;
                }
            }
        }

        if (f.controlledBy && this.formValues && this.fieldNameToUnique &&
            f.controlledBy !== 'Make_Contractor_as_Responsible_Person__c') {
            const uniqueId = this.fieldNameToUnique[f.controlledBy];
            const parentValue = uniqueId ? this.formValues[uniqueId] : null;

            const parentLabel = this.labelMap[f.controlledBy] || f.controlledBy;

            if (parentValue) {
                if (f.dataType === 'Date' && new Date(value) < new Date(parentValue)) {
                    return `${label} must be after ${parentLabel}`;
                }
            }
        }
        const startDateKey = Object.keys(this.formValues).find(key =>
            key.includes('RETL_Start_Date__c') || key.includes('StartDate')
        );
        const endDateKey = Object.keys(this.formValues).find(key =>
            key.includes('RETL_End_Date__c') || key.includes('EndDate')
        );

        let startDate = startDateKey ? this.formValues[startDateKey] : null;
        let endDate = endDateKey ? this.formValues[endDateKey] : null;
        const today = new Date();
        const selDate = new Date(startDate);
        const isToday =
            selDate.getFullYear() === today.getFullYear() &&
            selDate.getMonth() === today.getMonth() &&
            selDate.getDate() === today.getDate();
        //if (f.dataType === 'Time' || f.dataType === 'Date') {
        // Find matching keys dynamically
        const startKey = Object.keys(this.formValues).find(key =>
            key.includes('Start_Time') || key.includes('StartTime')
        );
        const endKey = Object.keys(this.formValues).find(key =>
            key.includes('End_Time') || key.includes('EndTime')
        );
        const startTime = startKey ? this.formValues[startKey] : null;
        const endTime = endKey ? this.formValues[endKey] : null;
        // if (startTime && endTime) {
        //     if (fieldName === 'RETL_End_Time__c' && endTime < startTime) return 'End time cannot be before Start time';
        //     if (fieldName === 'RETL_Start_Time__c' && startTime > endTime) return 'Start time cannot be after End time';
        // }
        if (isToday) {
            if (fieldName === 'RETL_Start_Time__c' && startDate && startTime) {

                // convert "HH:mm" to Date object for today
                const [h, m] = startTime.split(':').map(Number);
                const selectedTime = new Date();
                selectedTime.setHours(h, m, 0, 0);
                if (selectedTime < today) {
                    return 'Start time cannot be in the past';
                }
                else {
                    return '';
                }

            }
        }


        else {
            return '';
        }
        //}

        if (fieldName.includes('Expiry')) {
            if (new Date(value) < this.stripTime(new Date())) {
                return `${label} is expired`;
            } if (startDate && new Date(value) < new Date(startDate)) {
                return `${label} will be expired before starting the work`;
            } else if (endDate && new Date(value) < new Date(endDate)) {
                return `${label} will be expired before finishing the work`;
            }
        } else if (fieldName.includes('Issue')) {
            if (new Date(value) > this.stripTime(new Date())) {
                return `${label} not yet issued`;
            } else if (startDate && new Date(value) > new Date(startDate)) {
                return `${label} should not be after work start date`;
            }
        } else if (fieldName.includes('Start_Date') &&
            new Date(value) < this.stripTime(new Date())) {
            return `${label} cannot be past date`;
        } else if (fieldName.includes('End_Date') &&
            new Date(value) < this.stripTime(new Date())) {
            return `${label} cannot be past date`;
        }
        if (startDate === endDate && startTime > endTime) {
            return 'Invalid time';
        }
        return null;
    }
    stripTime(date) {
        return new Date(date.getFullYear(), date.getMonth(), date.getDate());
    }

    get comboboxClass() {
        return 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click' +
            (this.dropdownVisible ? ' slds-is-open' : '');
    }

    handleSearch(event) {
        this.searchTerm = event.target.value;
        const term = this.searchTerm.toLowerCase();
        // if (term.length === 0) {
        //     this.filteredDropdownValues = [];
        //     this.dropdownVisible = false;
        //     return;
        // }
        this.filteredDropdownValues = this.field.dropdownOptions
            .filter(c => c && c.toLowerCase().includes(term))
            .slice(0, 100); // show only top 10 matches
        this.dropdownVisible = this.filteredDropdownValues.length > 0;
    }

    hideDropdown() {
        this.dropdownVisible = false;
    }
    handleSelect(event) {
        const value = event.currentTarget.dataset.value;
        this.searchTerm = value;
        this.dropdownVisible = false;
        const fieldName = this.field.fieldName;
        let targetField = this.field;
        let error = this.validateField(value, targetField);
        const input = this.template.querySelector('lightning-input');
        if (input) {
            input.value = value;
            if (error) {
                input.setCustomValidity(error);
            } else {
                input.setCustomValidity('');
            }
            input.reportValidity();
        }
        this.sendValueToParent(fieldName, value);
    }
}