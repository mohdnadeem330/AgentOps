import { LightningElement, api, track, wire } from 'lwc';
import Images from "@salesforce/resourceUrl/RETLTenantPortalImages";
import getSectionFieldMap from '@salesforce/apex/RETL_ServiceRequestWizardController.getSectionFieldMap';
import getCountryPicklistValues from '@salesforce/apex/RETL_ServiceRequestWizardController.getCountryPicklistValues';
import createRecord from '@salesforce/apex/RETL_ServiceRequestWizardController.createRecord';
import createFileRecord from '@salesforce/apex/RETL_ServiceRequestWizardController.uploadDocuments';
import getFileSizeLimit from '@salesforce/apex/RETL_ServiceRequestWizardController.getTenantPortalSetting';
//import getUserInfo from '@salesforce/apex/RETL_ServiceRequestWizardController.getCurrentUserDetails';
import getCurrentUserDetails from '@salesforce/apex/RETL_ServiceRequestWizardController.getCurrentUserDetails';
//import createFileRecord from '@salesforce/apex/RETL_SRDocumentHandler.handleDocuments';
import getDocument from '@salesforce/apex/RETL_ServiceRequestWizardController.getDocument';
export default class Retl_TenantServiceRequestFieldMapping extends LightningElement {
    icon10image = Images + '/Request/icon10.png';
    @api selectedServiceType;
    @api selectedCategory;
    @api selectedSubCategory;
    @api currentStep;
    @api contactId
    @api orderId;
    @api storeName;
    @api formData;
    @api savedFilesByContractor = {}
    @api savedFilesBySection = {}
    @api accessToken
    @api mainContractorExistingData;
    @api requestSubmittingBy;
    @api networkName;
    userType;
    @track documentIdMap = {};
    @track sectionFields = [];
    @track contractorInstances = [];
    @track nationalityOptions = [];
    @track formValues = {};
    @track fieldNameToUnique = {};
    @track labelMap = {};
    @track allValidations = []
    accountId;
    user;
    showTerms = false;
    isContractor = false;
    addedContracts = false;
    isNotApplicable = false;
    isCaseCreated = false;
    hasError = false;
    accountMobileNormal
    accountEmailNormal
    accountMobileContractor
    accountEmailContractor
    activeSectionName
    errorText
    resposiblePersonType
    fileSizeLimit;
    networkName;
    isMainContractorData = false;

    connectedCallback() {
        if (this.mainContractorExistingData.Contact.RecordType.Name === 'Contractor' || this.mainContractorExistingData.Contact.RecordType.Name === 'DM Contact') {
            this.isMainContractorData = true;
            this.loadUserDetails();

        }
        this.fetchSectionFieldMap();
        if (this.mainContractorExistingData.Profile.Name === 'Retail Tenant Partner Login') {
            this.networkName = 'Tenant Portal';
        }
        else if (this.mainContractorExistingData.Profile.UserLicense.Name === 'Partner Community Login') {
            this.networkName = 'Contractor Business Portal';
        }
    }


    async loadUserDetails() {
        try {
            const data = await getCurrentUserDetails({ contactId: this.contactId });
            this.mainContractorExistingData = data;
            this.accountId = data.Contact?.AccountId;
             this.loadExistingDocuments(this.contactId, this.accountId);
        }
        catch (error) {
            console.error('Error loading user details:', error);

        }
    }
    @wire(getFileSizeLimit)
    wiredLimit({ error, data }) {
        if (data) {
            this.fileSizeLimit = data;
        } else if (error) {
            console.error('Error fetching file size limit:', error);
        }
    }

    // @wire(getUserInfo)
    // wiredUser({ data, error }) {
    //     if (data) {
    //         this.user = data;
    //         this.error = undefined;
    //     } else if (error) {
    //         this.error = error;
    //         this.user = undefined;
    //     }
    // }

    fetchSectionFieldMap() {
        getSectionFieldMap({
            category: this.selectedCategory,
            subCategory: this.selectedSubCategory,
            serviceType: this.selectedServiceType
        })
            .then(result => {
                const labelMap = {};
                this.sectionFields = Object.keys(result).map((section, sIdx) => {
                    const fieldsForSection = result[section] || [];
                    const sectionOrder = parseInt(fieldsForSection[0]?.sectionOrder || 0, 10);
                    const stepNumber = parseInt(fieldsForSection[0]?.stepNumber || 0, 10);
                    const safeSection = (section || 'section').replace(/\W+/g, '_');
                    const sectionKey = `${safeSection}_${sIdx}`;
                    const sectionVisible = fieldsForSection.length > 0
                        ? (fieldsForSection[0].sectionVisible === 'true')
                        : false;
                    this.formValues = this.formValues || {};
                    this.allValidations = this.allValidations || [];
                    // --- Normalize fields ---
                    let mappedFields = fieldsForSection.map(f => {
                        this.fieldNameToUnique[f.sfFieldName] = f.uniqueIdentifier;
                        const displayOrder = f.displayOrder ? parseInt(f.displayOrder, 10) : null;
                        const validations = f.validations
                            ? f.validations.split(',').map(v => v.trim())
                            : [];
                        // Push to global array for later use
                        validations.forEach(v => {
                            this.allValidations.push({
                                fieldApiName: f.sfFieldName,
                                uniqueIdentifier: f.uniqueIdentifier,
                                validationRule: v,
                                section: section,
                                stepNumber: stepNumber
                            });
                        });
                        //  normalize checkbox value to boolean
                        let normalizedValue;
                        if (f.dataType === 'Checkbox') {
                            normalizedValue = (f.value === true || f.value === 'true');
                        } else {
                            normalizedValue = f.value || '';
                        }
                        if (this.formData && this.formData[f.uniqueIdentifier] !== undefined) {
                            this.formValues[f.uniqueIdentifier] = this.formData[f.uniqueIdentifier];
                        } else {
                            this.formValues[f.uniqueIdentifier] = normalizedValue;
                        }
                        const value = '';
                        const isPicklist = f.dataType === 'Picklist';
                        const parentValue = f.parentPicklistValue || null;
                        let picklistOptions = [];
                        if (isPicklist && f.picklistVals) {
                            picklistOptions = f.picklistVals.split(/[,;]+/).map(v => (
                                {
                                    label: v.trim(),
                                    value: v.trim(),
                                    parent: parentValue,
                                    buttonClass: this.computePillClass(v, value)
                                }));
                        }
                        // fill labelMap
                        labelMap[f.sfFieldName] = f.formLabel;
                        const controlledBy = f.controlledBy
                            ? f.controlledBy.split(',').map(v => v.trim())
                            : [];
                        const fileValues = [];
                        return {
                            fieldName: f.sfFieldName,
                            sfObjectName: f.sfObjectName,
                            fieldLimit: f.fieldLimit,
                            label: f.formLabel,
                            sectionName: section,
                            dataType: f.dataType,
                            required: controlledBy.includes('Make_Contractor_as_Responsible_Person__c') ? false : f.required === 'true',
                            requiredOriginal: f.required === 'true',   //keep original required
                            displayOrder,
                            stepNumber: parseInt(f.stepNumber || 0, 10),
                            isPair: f.isPair === 'true',
                            pairOrder: f.pairOrder,
                            controlledBy,
                            fileValues,
                            uniqueIdentifier: f.uniqueIdentifier,
                            isPicklist,
                            parentPicklistValue: f.parentPicklistValue,
                            allPicklistOptions: picklistOptions,
                            picklistVals: f.picklistVals,
                            document: { fileValues },
                            dropdownOptions: f.dataType === 'Dropdown' && f.formLabel.includes('Nationality')
                                ? this.nationalityOptions
                                : f.picklistVals
                                    ? f.picklistVals.split(',').map(v => v.trim())
                                    : [],
                            validations: validations,
                            value: f.dataType !== 'Button' ? this.formValues[f.uniqueIdentifier] : !this.formValues[f.uniqueIdentifier] ? false : this.formValues[f.uniqueIdentifier],
                            visible: !isPicklist && !controlledBy.includes('Make_Contractor_as_Responsible_Person__c') ? true : (controlledBy && controlledBy.length)
                                ? false
                                : (controlledBy.includes('Make_Contractor_as_Responsible_Person__c')
                                    ? !controlledBy
                                    : true),
                            baseKey: `${sectionKey}_${f.sfFieldName}`,
                            errorMessage: f.errorMessage
                            //isDisabled : section ==='' && this.isMainContractorData &&  !this.isAddAnotherClicked?true:false
                        };
                    });
                    // remove fields with no displayOrder
                    mappedFields = mappedFields.filter(f => f.displayOrder !== null);
                    // --- Split button fields ---
                    const buttonFields = mappedFields
                        .filter(f => f.dataType === 'Button')
                        .map((f, idx) => ({
                            ...f,
                            buttonKey: `${sectionKey}_btn_${idx}`,
                            buttonClass: 'slds-button pill2 text-black slds-button_neutral'
                        }));
                    // --- Group other fields into orderedFields ---
                    const orderedFields = [];
                    let rowCounter = 0;
                    mappedFields
                        .filter(f => f.dataType !== 'Button')
                        .sort((a, b) => a.displayOrder - b.displayOrder)
                        .forEach(f => {
                            if (f.isPair) {
                                if (f.pairOrder === "1") {
                                    let pairGroup = mappedFields
                                        .filter(x => x.isPair && x.displayOrder === f.displayOrder)
                                        .sort((a, b) => parseInt(a.pairOrder, 10) - parseInt(b.pairOrder, 10));

                                    const rowKey = `${sectionKey}_row_${rowCounter++}`;
                                    orderedFields.push({
                                        isPair: true,
                                        fields: pairGroup.map(p => ({
                                            ...p,
                                            fieldKey: `${rowKey}_${p.fieldName}`
                                        })),
                                        rowKey
                                    });
                                }
                            }
                            else {
                                const rowKey = `${sectionKey}_row_${rowCounter++}`;
                                orderedFields.push({
                                    isSingle: true,
                                    field: { ...f, fieldKey: `${rowKey}_${f.fieldName}` },
                                    rowKey
                                });
                            }
                        });

                    return {
                        sectionKey,
                        sectionName: section,
                        stepTitle: fieldsForSection[0]?.stepTitle || '',
                        sectionVisible,
                        sectionOrder,
                        stepNumber,
                        buttonFields,
                        orderedFields
                    };
                });
                this.sectionFields.sort((a, b) => a.sectionOrder - b.sectionOrder);
                //console.log('this.sectionFields',JSON.stringify(this.sectionFields));
                this.labelMap = labelMap;
                this.restoreFiles();
                this.updateVisibility();
                console.log('this.sectionFields', JSON.stringify(this.sectionFields));
                this.dispatchEvent(new CustomEvent('formchange', {
                    detail: { ...this.formValues }
                }));
            })
            .catch(error => {
                console.error(' Error fetching field map:', error);
            });

    }

    restoreFiles() {
        // --- Restore normal section files ---
        if (this.savedFilesBySection) {
            Object.keys(this.savedFilesBySection).forEach(sectionName => {
                const fileMap = this.savedFilesBySection[sectionName];
                this.sectionFields = this.sectionFields.map(sec => {
                    if (sec.sectionName === sectionName) {
                        const newOrdered = sec.orderedFields.map(row => {
                            if (row.isSingle && fileMap[row.field.uniqueIdentifier]) {
                                return { ...row, field: { ...row.field, fileValues: fileMap[row.field.uniqueIdentifier] } };
                            }
                            if (row.isPair) {
                                const newFields = row.fields.map(f => {
                                    if (fileMap[f.uniqueIdentifier]) {
                                        return { ...f, fileValues: fileMap[f.uniqueIdentifier] };
                                    }
                                    return f;
                                });
                                return { ...row, fields: newFields };
                            }
                            return row;
                        });
                        return { ...sec, orderedFields: newOrdered };
                    }
                    return sec;
                });
            });
        }

        // --- Restore contractor files ---
        if (this.savedFilesByContractor) {
            this.contractorInstances = this.contractorInstances.map(c => {
                const fileMap = this.savedFilesByContractor[c.id];
                if (!fileMap) return c;

                const newFields = c.fields.map(row => {
                    if (row.isSingle && fileMap[row.field.uniqueIdentifier]) {
                        return { ...row, field: { ...row.field, fileValues: fileMap[row.field.uniqueIdentifier] } };
                    }
                    if (row.isPair) {
                        const newFields = row.fields.map(f => {
                            if (fileMap[f.uniqueIdentifier]) {
                                return { ...f, fileValues: fileMap[f.uniqueIdentifier] };
                            }
                            return f;
                        });
                        return { ...row, fields: newFields };
                    }
                    return row;
                });

                return { ...c, fields: newFields };
            });
        }
    }

    computePillClass(optValue, currentValue) {
        return `slds-button pill2 ${optValue === currentValue ? 'pill-selected' : 'slds-button_neutral'}`;
    }

    updateVisibility() {
        let contractorNotApplicable = false; //  global flag for Add Contractor button
        this.sectionFields = this.sectionFields.map(sec => {
            // find Not Applicable checkbox for this section
            const notApplicableField = sec.orderedFields
                .flatMap(item => item.isSingle ? [item.field] : item.fields)
                .find(f =>
                    f.fieldName === 'RETL_Not_Applicable__c' ||
                    f.fieldName?.includes('Not_Applicable') ||
                    f.fieldName?.includes('NotApplicable')
                );
            const notApplicableChecked = notApplicableField
                ? this.formValues?.[notApplicableField.uniqueIdentifier]
                : false;
            if (
                (sec.sectionName === 'Contractor Details' ||
                    sec.sectionName === 'Work Permit - Contractor Details' || sec.sectionName === 'Organizer' || sec.sectionName === 'Organizer Details') &&
                notApplicableChecked
            ) {
                contractorNotApplicable = true; // disable Add Contractor
            }
            const newOrdered = sec.orderedFields.map(item => {
                if (item.isSingle) {
                    const fld = { ...item.field };
                    // ControlledBy logic
                    if (fld.controlledBy && fld.controlledBy.includes('Make_Contractor_as_Responsible_Person__c')) {
                        const uniqueId = this.fieldNameToUnique[fld.controlledBy];
                        const parentVal = uniqueId ? this.formValues[uniqueId] : null;
                        fld.visible = !fld.controlledBy || !!parentVal;
                        fld.required = parentVal && fld.requiredOriginal ? true : !parentVal && fld.requiredOriginal ? false : false;
                    }
                    if (sec.sectionName === 'Contractor Details' || sec.sectionName === 'Work Permit - Contractor Details' || sec.sectionName === 'Organizer' || sec.sectionName === 'Organizer Details') {
                        this.resposiblePersonType = sec.sectionName === 'Contractor Details' || sec.sectionName === 'Work Permit - Contractor Details' ? 'Contractor' : 'Organizer';
                        const hasOneContractorMinimum = (this.allValidations || []).some(v => v.validationRule === 'OneContractorMinimum');
                        const contractorCount = this.contractorInstances?.length || 0;
                        if (contractorCount === 0 && hasOneContractorMinimum && (fld.fieldName === 'RETL_Not_Applicable__c' || fld.fieldName?.includes('Not_Applicable') || fld.fieldName?.includes('NotApplicable'))) {
                            fld.visible = false;
                        }
                    }
                    // Picklist handling (unchanged)
                    if (fld.isPicklist) {
                        const parentApi = (fld.controlledBy && fld.controlledBy.length)
                            ? fld.controlledBy[0]
                            : null;
                        if (parentApi) {
                            const uniqueId = this.fieldNameToUnique[parentApi];
                            const parentValue = uniqueId ? this.formValues[uniqueId] : null;
                            if (parentValue) {
                                fld.picklistOptions = (fld.allPicklistOptions || []).filter(opt =>
                                    opt.parent === parentValue
                                );
                                fld.picklistOptions = fld.picklistOptions.map(opt => ({
                                    ...opt,
                                    buttonClass: opt.value === fld.value
                                        ? 'slds-button pill2 pill-selected'
                                        : 'slds-button pill2'
                                }));
                                fld.visible = (fld.parentPicklistValue === parentValue);
                            } else {
                                fld.picklistOptions = [];
                                fld.visible = false;
                            }
                        } else {
                            fld.picklistOptions = (fld.allPicklistOptions || []).map(opt => ({
                                ...opt,
                                buttonClass: opt.value === fld.value
                                    ? 'slds-button pill2 pill-selected'
                                    : 'slds-button pill2'
                            }));
                            fld.visible = true;
                        }
                    }
                    // Not Applicable logic for normal fields
                    if (notApplicableChecked && fld.uniqueIdentifier !== notApplicableField?.uniqueIdentifier) {
                        if (!this.notApplicableCache[fld.uniqueIdentifier]) {
                            this.notApplicableCache[fld.uniqueIdentifier] = this.formValues[fld.uniqueIdentifier];
                        }
                        //console.log('fld.dataType', fld.dataType);
                        if (fld.dataType === 'Checkbox') {
                            this.formValues[fld.uniqueIdentifier] = false;
                        } else {
                            this.formValues[fld.uniqueIdentifier] = '';
                        }
                        fld.isDisabled = true;
                        fld.required = false;
                    }

                    else {
                        if (this.notApplicableCache[fld.uniqueIdentifier]) {
                            this.formValues[fld.uniqueIdentifier] = this.notApplicableCache[fld.uniqueIdentifier];
                            delete this.notApplicableCache[fld.uniqueIdentifier];
                        }
                        fld.isDisabled = false;
                        const hasParentDependency = Array.isArray(fld.controlledBy) && fld.controlledBy.length > 0 && !fld.controlledBy.includes('Make_Contractor_as_Responsible_Person__c');
                        const parentFilled = hasParentDependency && fld.controlledBy.some(api => !!this.getFormValueByApi(api));

                        if (fld.isControlledRequired || parentFilled) {
                            fld.required = true;
                        } else {
                            fld.required = fld.requiredOriginal;
                        }
                    }
                    if ((sec.sectionName === 'Contractor Details' || sec.sectionName === 'Organizer Details' || sec.sectionName === 'Organizer') && this.isMainContractorData && !this.isAddAnotherClicked) {
                        if(sec.sectionName === 'Contractor Details'){
                            fld.isDisabled = true;
                        }

                        if (fld.fieldName === 'Make_Contractor_as_Responsible_Person__c') {
                            fld.isDisabled = false;
                            //  fld.value = true;
                        }
                        fld.isMainContractorField = true;
                    }
                    return { ...item, field: fld };
                }
                if (item.isPair) {
                    const fields = item.fields.map(fld => {
                        const updated = { ...fld };
                        if (fld.controlledBy.includes('Make_Contractor_as_Responsible_Person__c')) {
                            const uniqueId = this.fieldNameToUnique[fld.controlledBy];
                            updated.visible = !fld.controlledBy || !!this.formValues[uniqueId];
                            updated.required = !!this.formValues[uniqueId]
                        }
                        if (notApplicableChecked && fld.uniqueIdentifier !== notApplicableField?.uniqueIdentifier) {
                            if (!this.notApplicableCache[fld.uniqueIdentifier]) {
                                this.notApplicableCache[fld.uniqueIdentifier] = this.formValues[fld.uniqueIdentifier];
                            }
                            if (fld.dataType === 'Checkbox') {
                                this.formValues[fld.uniqueIdentifier] = false;
                            } else {
                                this.formValues[fld.uniqueIdentifier] = '';
                            }
                            updated.isDisabled = true;
                            updated.required = false;
                        } else {
                            if (this.notApplicableCache[fld.uniqueIdentifier]) {
                                this.formValues[fld.uniqueIdentifier] = this.notApplicableCache[fld.uniqueIdentifier];
                                delete this.notApplicableCache[fld.uniqueIdentifier];
                            }
                            updated.isDisabled = false;
                            const hasParentDependency = Array.isArray(updated.controlledBy) && updated.controlledBy.length > 0 && !updated.controlledBy.includes('Make_Contractor_as_Responsible_Person__c');
                            const parentFilled = hasParentDependency && updated.controlledBy.some(api => !!this.getFormValueByApi(api));

                            if (updated.isControlledRequired || parentFilled) {
                                updated.required = true;
                            } else {
                                updated.required = updated.requiredOriginal;
                            }
                        }
                        if ((sec.sectionName === 'Contractor Details' || sec.sectionName === 'Organizer Details' || sec.sectionName === 'Organizer') && this.isMainContractorData && !this.isAddAnotherClicked) {
                            if(sec.sectionName === 'Contractor Details'){
                                updated.isDisabled = true;
                            }
                            
                            if (fld.fieldName === 'Make_Contractor_as_Responsible_Person__c') {
                                //  fld.value = true;
                            }
                            updated.isMainContractorField = true;
                        }
                        return updated;
                    });
                    return { ...item, fields };
                }

                return item;
            });
            return { ...sec, orderedFields: newOrdered };
        });
        //  Disable Add Contractor button if Not Applicable is checked
        this.isNotApplicable = contractorNotApplicable;
        this.formValues = { ...this.formValues };
        this.sectionFields = JSON.parse(JSON.stringify(this.sectionFields));
    }

    // --- child fieldchange event handler ---
    handleChange(event) {
        //event.preventDefault();
        //const tag = event.target.tagName.toLowerCase();
        const tag = event.target.dataset.type;
        const isButton = tag === 'button';
        let uniqueIdentifier, fieldName, value, contractorid;
        if (isButton) {
            contractorid = event.target.dataset.contractorid || null;
            // --- Button (Pill) Field Handling ---
            const sectionKey = event.target.dataset.section;
            uniqueIdentifier = event.target.dataset.uniqueid;
            fieldName = event.target.dataset.field;
            const isAlreadyActive = event.target.classList.contains('pill2-active');
            console.log('isAlreadyActive', isAlreadyActive);
            const newValue = !isAlreadyActive; // toggle
            console.log('newValue', newValue);
            this.formValues[uniqueIdentifier] = newValue;
            // Remove "active" class from other buttons in same section only
            const sectionButtons = this.template.querySelectorAll(
                `button[data-section="${sectionKey}"][data-field="${fieldName}"]`
            );
            // sectionButtons.forEach(btn => btn.classList.remove('pill2-active'));
            //Toggle logic: if already active → deselect (clear value)
            if (isAlreadyActive) {
                event.target.classList.remove('pill2-active');
            } else {
                // Otherwise, select this one
                event.target.classList.add('pill2-active');
            }
            //Keep section data model consistent
            this.sectionFields = this.sectionFields.map(sec => {
                if (sec.sectionKey !== sectionKey) return sec;
                return {
                    ...sec,
                    buttonFields: sec.buttonFields.map(btn => {
                        if (btn.fieldName === fieldName) {
                            console.log('btn before', JSON.stringify(btn));
                            btn =
                            {
                                ...btn,
                                value: !isAlreadyActive,
                                buttonClass: !isAlreadyActive
                                    ? 'slds-button pill2 text-black slds-button_neutral pill2-active'
                                    : 'slds-button pill2 text-black slds-button_neutral'
                            };
                            console.log('btn after', JSON.stringify(btn));
                            return btn;
                        }
                        return btn;
                    })
                };
            });

            //  Update dependent requirements after button value change
            this.sectionFields = JSON.parse(JSON.stringify(this.sectionFields));
            this.updateDependentFieldRequirements(fieldName);
        } else {
            // Normal inputs (text, checkbox, etc.)
            ({ uniqueIdentifier, fieldName, value, contractorid } = event.detail);
            this.formValues[uniqueIdentifier] = value;
            let fieldValue;
            if (fieldName === 'Mobile_and_Email_same_as_contractor_deta__c') {
                if (value) {
                    //  When checked → copy from contractor
                    let contractorEmailId = this.getUniqueId('Email__c');
                    let contractorMobileId = this.getUniqueId('MobileNumber__c');
                    let userEmailId = this.getUniqueId('Email');
                    let userMobileId = this.getUniqueId('MobilePhone');

                    const emailVal = contractorEmailId ? this.formValues[contractorEmailId] || '' : '';
                    const mobileVal = contractorMobileId ? this.formValues[contractorMobileId] || '' : '';

                    if (userEmailId) this.updateFieldValue(userEmailId, emailVal);
                    if (userMobileId) this.updateFieldValue(userMobileId, mobileVal);

                } else {
                    //  When unchecked → clear the values
                    const emailId = this.getUniqueId('Email');
                    const mobileId = this.getUniqueId('MobilePhone');
                    if (emailId) {
                        this.updateFieldValue(emailId, '');
                        this.formValues[emailId] = ''; // ensures data model also clears
                    }
                    if (mobileId) {
                        this.updateFieldValue(mobileId, '');
                        this.formValues[mobileId] = '';
                    }
                    // Re-render fields so UI updates immediately
                    this.sectionFields = [...this.sectionFields];
                }
            }
            if (fieldName === 'MobileNumber__c') {
                this.accountMobileNormal = value;
            }
            if (fieldName === 'EmailAddress__c') {
                this.accountEmailNormal = value;
            }
            this.updateVisibility();
            this.updateDependentFieldRequirements(fieldName)

        }
        this.dispatchEvent(new CustomEvent('formchange', {
            detail: { contractorid, [uniqueIdentifier]: value }
        }));
        // --- Contractor case ---
        if (contractorid) {
            if (fieldName === 'MobileNumber__c') {
                this.accountMobileContractor = value;
            }
            if (fieldName === 'EmailAddress__c') {
                this.accountEmailContractor = value;
            }
            this.contractorInstances = this.contractorInstances.map(c => {
                if (c.id === contractorid) {
                    return {
                        ...c,
                        formValues: { ...c.formValues, [uniqueIdentifier]: value },
                        fields: c.fields.map(row => {
                            if (row.isSingle && row.field && row.field.uniqueIdentifier === uniqueIdentifier) {
                                return { ...row, field: { ...row.field, value } };
                            }

                            if (row.isPair && Array.isArray(row.fields)) {
                                return {
                                    ...row,
                                    fields: row.fields.map(f =>
                                        f.uniqueIdentifier === uniqueIdentifier
                                            ? { ...f, value }
                                            : f
                                    )
                                };
                            }
                            return row;
                        })
                    };
                }
                return c;
            });
            // Notify parent
            this.dispatchEvent(new CustomEvent('formchange', {
                detail: { contractorid, [uniqueIdentifier]: value }
            }));
        }
        // --- Special case still works ---
        if (this.selectedCategory === 'General Request' && this.selectedServiceType === 'Enquiry') {
            this.sendValueToParent(fieldName, value);
        }
        console.log('this.sectionFields end og handleChange', JSON.stringify(this.sectionFields))
    }
    existingDocs;
    loadExistingDocuments(contactId, accountId) {
        getDocument({ contactId: contactId, accountId: accountId })
            .then(result => {
               // console.log('Existing Docs: ', JSON.stringify(result));

                // Convert list into a map by documentType for fast lookup
                this.existingDocs = {};
                result.forEach(doc => {
                    this.existingDocs[doc.documentType] = {
                        filename: doc.fileName,
                        contentDocumentId: doc.contentDocumentId,
                        documentType: doc.documentType
                    };
                });

                // Add to fileValues for matching fields
                this.prepopulateFileValues();
            })
            .catch(error => {
                console.error('Error in loadExistingDocuments', error);
            });

    }

    prepopulateFileValues() {
        if (!this.sectionFields || !this.isMainContractorData) return;

        const normalize = (str) => {
            if (!str) return "";
            return str
                .toLowerCase()
                .replace(/attachment|copy|upload|file|document|no/gi, "")
                .replace(/[^\w]/g, "")
                .replace(/ing$/gi, "e")
                .trim();
        };

        this.sectionFields = this.sectionFields.map(sec => {
            if (
                (sec.sectionName === 'Contractor Details' ||
                    sec.sectionName === 'Organizer Details' ||
                    sec.sectionName === 'Organizer') &&
                this.isMainContractorData
            ) {
                sec.orderedFields = sec.orderedFields.map(row => {

                    const applyMatch = (f) => {
                        if (f.dataType !== 'File') return f;

                        let fieldKey = normalize(f.label);

                        Object.values(this.existingDocs).forEach(doc => {
                            let docKey = normalize(doc.documentType);
                            console.log('docKey',docKey);
                            console.log('fieldKey',fieldKey);
                            if (fieldKey.includes(docKey) || docKey.includes(fieldKey)) {
                                f.fileValues = [{
                                    filename: doc.filename,
                                    contentDocumentId: doc.contentDocumentId,
                                    documentType: doc.documentType,
                                    isExisting: true
                                }];
                            }
                        });

                        return f;
                    };

                    if (row.isSingle) {
                        row.field = applyMatch(row.field);
                        return row;
                    }

                    if (row.isPair) {
                        row.fields = row.fields.map(f => applyMatch(f));
                    }

                    return row;
                });
            }
            return sec;
        });

        console.log("After smart pre-population", JSON.stringify(this.sectionFields));
    }
    existingDocs;
    loadExistingDocuments(contactId, accountId) {
        getDocument({ contactId: contactId, accountId: accountId })
            .then(result => {
               // console.log('Existing Docs: ', JSON.stringify(result));

                // Convert list into a map by documentType for fast lookup
                this.existingDocs = {};
                result.forEach(doc => {
                    this.existingDocs[doc.documentType] = {
                        filename: doc.fileName,
                        contentDocumentId: doc.contentDocumentId,
                        documentType: doc.documentType
                    };
                });

                // Add to fileValues for matching fields
                this.prepopulateFileValues();
            })
            .catch(error => {
                console.error('Error in loadExistingDocuments', error);
            });

    }

    prepopulateFileValues() {
        if (!this.sectionFields || !this.isMainContractorData) return;

        const normalize = (str) => {
            if (!str) return "";
            return str
                .toLowerCase()
                .replace(/attachment|copy|upload|file|document|no/gi, "")
                .replace(/[^\w]/g, "")
                .replace(/ing$/gi, "e")
                .trim();
        };

        this.sectionFields = this.sectionFields.map(sec => {
            if (
                (sec.sectionName === 'Contractor Details' ||
                    sec.sectionName === 'Organizer Details' ||
                    sec.sectionName === 'Organizer') &&
                this.isMainContractorData
            ) {
                sec.orderedFields = sec.orderedFields.map(row => {

                    const applyMatch = (f) => {
                        if (f.dataType !== 'File') return f;

                        let fieldKey = normalize(f.label);

                        Object.values(this.existingDocs).forEach(doc => {
                            let docKey = normalize(doc.documentType);
                            if (fieldKey.includes(docKey) || docKey.includes(fieldKey)) {
                                f.fileValues = [{
                                    filename: doc.filename,
                                    contentDocumentId: doc.contentDocumentId,
                                    documentType: doc.documentType,
                                    isExisting: true
                                }];
                            }
                        });

                        return f;
                    };

                    if (row.isSingle) {
                        row.field = applyMatch(row.field);
                        return row;
                    }

                    if (row.isPair) {
                        row.fields = row.fields.map(f => applyMatch(f));
                    }

                    return row;
                });
            }
            return sec;
        });

    }
    existingDocs;
    loadExistingDocuments(contactId, accountId) {
        getDocument({ contactId: contactId, accountId: accountId })
            .then(result => {
               // console.log('Existing Docs: ', JSON.stringify(result));

                // Convert list into a map by documentType for fast lookup
                this.existingDocs = {};
                result.forEach(doc => {
                    this.existingDocs[doc.documentType] = {
                        filename: doc.fileName,
                        contentDocumentId: doc.contentDocumentId,
                        documentType: doc.documentType
                    };
                });

                // Add to fileValues for matching fields
                this.prepopulateFileValues();
            })
            .catch(error => {
                console.error('Error in loadExistingDocuments', error);
            });

    }

    prepopulateFileValues() {
        if (!this.sectionFields || !this.isMainContractorData) return;

        const normalize = (str) => {
            if (!str) return "";
            return str
                .toLowerCase()
                .replace(/attachment|copy|upload|file|document|no/gi, "")
                .replace(/[^\w]/g, "")
                .replace(/ing$/gi, "e")
                .trim();
        };

        this.sectionFields = this.sectionFields.map(sec => {
            if (
                (sec.sectionName === 'Contractor Details' ||
                    sec.sectionName === 'Organizer Details' ||
                    sec.sectionName === 'Organizer') &&
                this.isMainContractorData
            ) {
                sec.orderedFields = sec.orderedFields.map(row => {

                    const applyMatch = (f) => {
                        if (f.dataType !== 'File') return f;

                        let fieldKey = normalize(f.label);

                        Object.values(this.existingDocs).forEach(doc => {
                            let docKey = normalize(doc.documentType);
                            if (fieldKey.includes(docKey) || docKey.includes(fieldKey)) {
                                f.fileValues = [{
                                    filename: doc.filename,
                                    contentDocumentId: doc.contentDocumentId,
                                    documentType: doc.documentType,
                                    isExisting: true
                                }];
                            }
                        });

                        return f;
                    };

                    if (row.isSingle) {
                        row.field = applyMatch(row.field);
                        return row;
                    }

                    if (row.isPair) {
                        row.fields = row.fields.map(f => applyMatch(f));
                    }

                    return row;
                });
            }
            return sec;
        });

    }

    updateDependentFieldRequirements(changedField) {
        if (!this.formValues || !this.sectionFields) {
            console.warn('Missing formValues or sectionFields. Exiting.');
            return;
        }
        // Track total updates
        //let updatedCount = 0;
        // Loop through each section
       // console.log('this.sectionFields startin og updateDependentFieldRequirements', JSON.stringify(this.sectionFields))
        this.sectionFields = this.sectionFields.map(section => {
            //console.groupCollapsed(`Section: ${section.sectionName || 'Unnamed Section'}`);
            const updatedOrderedFields = section.orderedFields.map(row => {
                // Single field rows
                if (row.isSingle && row.field) {
                    let field = { ...row.field };
                    const ctrl = field.controlledBy;
                   // console.log('ctrl', JSON.stringify(ctrl));
                    if (Array.isArray(ctrl) && ctrl.length > 0) {
                        const dependsOnChanged = ctrl.includes(changedField);
                        const skipResponsibleRule =
                            ctrl.includes('Make_Contractor_as_Responsible_Person__c') &&
                            field.requiredOriginal === false;

                        if (dependsOnChanged) {
                            const isAnyParentFilled = ctrl.some(
                                parentApi => !!this.getFormValueByApi(parentApi)
                            );

                            let newRequired;

                            if (skipResponsibleRule) {
                                newRequired = false;  // Never make it required
                            } else {
                                newRequired = isAnyParentFilled ? true : field.requiredOriginal;
                            }

                            field.required = newRequired;
                            field.isControlledRequired = true;
                        } else {
                            field.isControlledRequired = false;
                        }
                    }
                    return { ...row, field };
                }

                // Pair fields
                if (row.isPair && Array.isArray(row.fields)) {
                    const updatedFields = row.fields.map(f => {
                        let field = { ...f };
                        const ctrl = field.controlledBy;
                        if (Array.isArray(ctrl) && ctrl.length > 0) {
                            const dependsOnChanged = ctrl.includes(changedField);
                            const skipResponsibleRule =
                                ctrl.includes('Make_Contractor_as_Responsible_Person__c') &&
                                field.requiredOriginal === false;

                            if (dependsOnChanged) {
                                const isAnyParentFilled = ctrl.some(
                                    parentApi => !!this.getFormValueByApi(parentApi)
                                );

                                let newRequired;

                                if (skipResponsibleRule) {
                                    newRequired = false;  // Never make it required
                                } else {
                                    newRequired = isAnyParentFilled ? true : field.requiredOriginal;
                                }

                                field.required = newRequired;
                                field.isControlledRequired = true;
                            } else {
                                field.isControlledRequired = false;
                            }
                        }
                        return field;
                    });
                    return { ...row, fields: updatedFields };
                }
                return row;
            });
            return { ...section, orderedFields: updatedOrderedFields };
        });
        this.sectionFields = JSON.parse(JSON.stringify(this.sectionFields)); // Force re-render
      //  console.log('this.sectionFields end og updateDependentFieldRequirements', JSON.stringify(this.sectionFields))
    }

    handleContractorResponsibleToggle(event) {
        const { contractorId, fieldName, value } = event.detail;

        if (fieldName !== 'Make_Contractor_as_Responsible_Person__c') return;
        const isResponsible = value === true || value === 'true';
        this.contractorInstances = this.contractorInstances.map(contractor => {
            if (contractor.id !== contractorId) return contractor;
            contractor.isResponsible = isResponsible;
            const updatedFields = contractor.fields.map(row => {
                if (row.isSingle && row.field) {
                    const f = { ...row.field };
                    if (f.controlledBy?.includes('Make_Contractor_as_Responsible_Person__c')) {
                        f.visible = isResponsible;
                        f.required = isResponsible ? f.requiredOriginal : false;
                    }
                    return { ...row, field: f };
                }
                if (row.isPair && row.fields) {
                    const updatedRowFields = row.fields.map(f => {
                        const updated = { ...f };
                        if (updated.controlledBy?.includes('Make_Contractor_as_Responsible_Person__c')) {
                            updated.visible = isResponsible;
                            updated.required = isResponsible ? updated.requiredOriginal : false;
                        }
                        return updated;
                    });
                    return { ...row, fields: updatedRowFields };
                }
                return row;
            });
            return {
                ...contractor,
                isResponsible: isResponsible,
                fields: updatedFields
            };
        });
        this.contractorInstances = JSON.parse(JSON.stringify(this.contractorInstances));
        this.sectionFields = this.sectionFields.map(section => {
            return {
                ...section,
                isResponsible: isResponsible
            };
        })
        this.sectionFields = JSON.parse(JSON.stringify(this.sectionFields));
    }

    getFormValueByApi(apiName) {
        if (!this.formValues || !apiName) return null;
        const matchKey = Object.keys(this.formValues).find(key => {
            const parts = key.split('-');
            return parts.some(part => part === apiName);
        });
        return matchKey ? this.formValues[matchKey] : null;
    }

    updateFieldValue(uniqueId, newValue, { refresh = true } = {}) {
        let updated = false;
        if (newValue === null || newValue === undefined) {
            newValue = '';
        }
        // --- 1️ Contractor Instances ---
        const updatedContractors = (this.contractorInstances || []).map(c => {
            let foundInContractor = false;
            const updatedFields = c.fields.map(row => {
                if (row.isSingle && row.field?.uniqueIdentifier === uniqueId) {
                    foundInContractor = true;
                    return { ...row, field: { ...row.field, value: newValue } };
                }
                if (row.isPair && Array.isArray(row.fields)) {
                    const updatedPair = row.fields.map(f => {
                        if (f.uniqueIdentifier === uniqueId) {
                            foundInContractor = true;
                            return { ...f, value: newValue };
                        }
                        return f;
                    });
                    return { ...row, fields: updatedPair };
                }
                return row;
            });

            if (foundInContractor) {
                updated = true;
                return {
                    ...c,
                    fields: updatedFields,
                    formValues: { ...c.formValues, [uniqueId]: newValue }
                };
            }
            return c;
        });
        this.contractorInstances = [...updatedContractors];
        // --- 2️ Section Fields ---
        if (!updated) {
            const updatedSections = (this.sectionFields || []).map(sec => {
                const updatedOrderedFields = sec.orderedFields.map(row => {
                    if (row.isSingle && row.field?.uniqueIdentifier === uniqueId) {
                        updated = true;
                        return { ...row, field: { ...row.field, value: newValue } };
                    }
                    if (row.isPair && Array.isArray(row.fields)) {
                        const updatedPair = row.fields.map(f => {
                            if (f.uniqueIdentifier === uniqueId) {
                                updated = true;
                                return { ...f, value: newValue };
                            }
                            return f;
                        });
                        return { ...row, fields: updatedPair };
                    }
                    return row;
                });
                return { ...sec, orderedFields: updatedOrderedFields };
            });
            this.sectionFields = [...updatedSections];
            if (updated) {
                this.formValues[uniqueId] = newValue;
            }
        }
        if (updated) {
            if (refresh) this.updateVisibility?.();
        } else {
            console.warn(` Field ${uniqueId} not found`);
        }
    }

    sendValueToParent(fieldName, value) {
        this.dispatchEvent(
            new CustomEvent('enquirycategoryselected', {
                detail: { fieldName: fieldName, value: value },
                bubbles: true,
                composed: true
            })
        );
    }

    getUniqueId(fieldName) {
        let uniqueId = null;
        for (const section of this.sectionFields || []) {
            for (const row of section.orderedFields || []) {
                //Case 1: Single field
                if (row.isSingle && row.field?.fieldName === fieldName) {
                    uniqueId = row.field.uniqueIdentifier;
                    break;
                }
                // Case 2: Paired fields
                if (row.isPair && Array.isArray(row.fields)) {
                    const found = row.fields.find(f => f.fieldName === fieldName);
                    if (found) {
                        uniqueId = found.uniqueIdentifier;
                        break;
                    }
                }
            }
            if (uniqueId) break; // stop once found
        }
        return uniqueId;
    }

    // --- AutoPopulation ---
    handleAutoPopulation(action, contractorid = null, contractorFormValues = null) {
        // helper to find uniqueIdentifiers by fieldName (for Email or Mobile)
        const findFieldUniqueId = (fields, apiNames) => {
            for (const row of fields) {
                if (row.isSingle && row.field) {
                    const f = row.field;
                    if (apiNames.includes(f.fieldName)) return f.uniqueIdentifier;
                }
                if (row.isPair && Array.isArray(row.fields)) {
                    for (const f of row.fields) {
                        if (apiNames.includes(f.fieldName)) return f.uniqueIdentifier;
                    }
                }
            }
            return null;
        };

        // --- PER-CONTRACTOR MODE ---
        if (contractorid) {
            this.contractorInstances = this.contractorInstances.map(c => {
                if (c.id !== contractorid) return c;
                const formVals = contractorFormValues || { ...c.formValues };
                const emailUid = findFieldUniqueId(c.fields, ['Email', 'EmailAddress__c']);
                const mobileUid = findFieldUniqueId(c.fields, ['MobilePhone', 'MobileNumber__c']);
                if (!emailUid && !mobileUid) return c;
                // ensure cache
                if (!c.notApplicableCache) c.notApplicableCache = {};
                if (action === 'Add') {
                    if (emailUid) {
                        c.notApplicableCache[emailUid] = formVals[emailUid] || '';
                        formVals[emailUid] = this.accountEmailContractor || '';
                    }
                    if (mobileUid) {
                        c.notApplicableCache[mobileUid] = formVals[mobileUid] || '';
                        formVals[mobileUid] = this.accountMobileContractor || '';
                    }
                } else if (action === 'Remove') {
                    if (emailUid) {
                        formVals[emailUid] = c.notApplicableCache[emailUid] || '';
                        c.notApplicableCache[emailUid] = null;
                    }
                    if (mobileUid) {
                        formVals[mobileUid] = c.notApplicableCache[mobileUid] || '';
                        c.notApplicableCache[mobileUid] = null;
                    }
                }

                // update field objects so UI updates
                const updatedFields = c.fields.map(row => {
                    if (row.isSingle && row.field) {
                        const f = row.field;
                        if (f.uniqueIdentifier === emailUid || f.uniqueIdentifier === mobileUid) {
                            return { ...row, field: { ...f, value: formVals[f.uniqueIdentifier] } };
                        }
                    }
                    if (row.isPair && Array.isArray(row.fields)) {
                        return {
                            ...row,
                            fields: row.fields.map(f =>
                                f.uniqueIdentifier === emailUid || f.uniqueIdentifier === mobileUid
                                    ? { ...f, value: formVals[f.uniqueIdentifier] }
                                    : f
                            )
                        };
                    }
                    return row;
                });

                return { ...c, formValues: formVals, fields: updatedFields };
            });
            return;
        }
        // --- GLOBAL MODE ---
        const contractorSection = this.sectionFields.find(
            s => s.sectionName === 'Contractor Details' || s.sectionName === 'Work Permit - Contractor Details' || s.sectionName === 'Organizer' || s.sectionName === 'Organizer Details'
        );
        if (!contractorSection) return;
        // find Email / Mobile uniqueIdentifiers in global section
        const emailUid = findFieldUniqueId(contractorSection.orderedFields, ['Email', 'EmailAddress__c']);
        const mobileUid = findFieldUniqueId(contractorSection.orderedFields, ['MobilePhone', 'MobileNumber__c']);

        // ensure cache
        if (!this.notApplicableCache) this.notApplicableCache = {};
        if (action === 'Add') {
            if (emailUid) {
                this.notApplicableCache[emailUid] = this.formValues[emailUid] || '';
                this.formValues[emailUid] = this.accountEmailNormal || '';
            }
            if (mobileUid) {
                this.notApplicableCache[mobileUid] = this.formValues[mobileUid] || '';
                this.formValues[mobileUid] = this.accountMobileNormal || '';
            }
        } else if (action === 'Remove') {
            if (emailUid) {
                this.formValues[emailUid] = this.notApplicableCache[emailUid] || '';
                this.notApplicableCache[emailUid] = null;
            }
            if (mobileUid) {
                this.formValues[mobileUid] = this.notApplicableCache[mobileUid] || '';
                this.notApplicableCache[mobileUid] = null;
            }
        }

        // sync UI fields
        this.sectionFields = this.sectionFields.map(sec => {
            const newOrdered = sec.orderedFields.map(row => {
                if (row.isSingle && row.field) {
                    const f = row.field;
                    if (f.uniqueIdentifier === emailUid || f.uniqueIdentifier === mobileUid) {
                        return { ...row, field: { ...f, value: this.formValues[f.uniqueIdentifier] } };
                    }
                }
                if (row.isPair && Array.isArray(row.fields)) {
                    return {
                        ...row,
                        fields: row.fields.map(f =>
                            f.uniqueIdentifier === emailUid || f.uniqueIdentifier === mobileUid
                                ? { ...f, value: this.formValues[f.uniqueIdentifier] }
                                : f
                        )
                    };
                }
                return row;
            });
            return { ...sec, orderedFields: newOrdered };
        });
    }

    // helper: rebuild saved files map for sections
    buildSavedFilesBySection(sectionFields) {
        const saved = {};
        (sectionFields || []).forEach(sec => {
            const fileMap = {};
            (sec.orderedFields || []).forEach(row => {
                if (row.isSingle && row.field?.fileValues?.length) {
                    fileMap[row.field.uniqueIdentifier] = [...row.field.fileValues];
                }
                if (row.isPair && Array.isArray(row.fields)) {
                    row.fields.forEach(f => {
                        if (f.fileValues?.length) fileMap[f.uniqueIdentifier] = [...f.fileValues];
                    });
                }
            });
            saved[sec.sectionName] = fileMap;
        });
        return saved;
    }

    // helper: rebuild saved files map for contractors
    buildSavedFilesByContractor(contractorInstances) {
        const saved = {};
        (contractorInstances || []).forEach(contractor => {
            const fileMap = {};
            (contractor.fields || []).forEach(row => {
                if (row.isSingle && row.field?.fileValues?.length) {
                    fileMap[row.field.uniqueIdentifier] = [...row.field.fileValues];
                }
                if (row.isPair && Array.isArray(row.fields)) {
                    row.fields.forEach(f => {
                        if (f.fileValues?.length) fileMap[f.uniqueIdentifier] = [...f.fileValues];
                    });
                }
            });
            saved[contractor.id] = fileMap;
        });
        return saved;
    }

    // --- Upload handler ---
    handleFileUpload(event) {
        const { files, fieldName, fieldLabel, uniqueIdentifier, contractorid, contentVersionId, documentId } = event.detail;
        if (!files || files.length === 0) {
            console.warn('No files selected');
            return;
        }
        Array.from(files).forEach(file => {
            //const reader = new FileReader();
            // reader.onload = () => {
            //     const base64 = reader.result.split(',')[1];
            const fileData = {
                documentType: fieldLabel,
                filename: file.name,
                contentVersionId: contentVersionId
                //base64: base64
            };
            this.documentIdMap[fieldLabel] = documentId;
            if (contractorid) {
                // update contractorInstances immutably
                this.contractorInstances = (this.contractorInstances || []).map(contractor => {
                    if (contractor.id !== contractorid) return contractor;
                    return {
                        ...contractor,
                        formValues: { ...contractor.formValues, [uniqueIdentifier]: 'File Added' },
                        fields: (contractor.fields || []).map(row => {
                            // single
                            if (row.isSingle && row.field.uniqueIdentifier === uniqueIdentifier) {
                                return {
                                    ...row,
                                    field: {
                                        ...row.field,
                                        fileValues: [...(row.field.fileValues || []), fileData],
                                        value: row.field.label,
                                        errorMessage: ''// clear error
                                    }
                                };
                            }
                            // pair
                            if (row.isPair && Array.isArray(row.fields)) {
                                const newFields = row.fields.map(f => {
                                    if (f.uniqueIdentifier === uniqueIdentifier) {
                                        return {
                                            ...f,
                                            fileValues: [...(f.fileValues || []), fileData],
                                            value: f.label,
                                            errorMessage: ''
                                        };
                                    }
                                    return f;
                                });
                                return { ...row, fields: newFields };
                            }
                            return row;
                        })
                    };
                });

                // rebuild savedFilesByContractor from full contractorInstances
                this.savedFilesByContractor = this.buildSavedFilesByContractor(this.contractorInstances);
            } else {
                this.formValues[uniqueIdentifier] = 'File Added';
                // update sectionFields immutably
                this.sectionFields = (this.sectionFields || []).map(sec => {
                    return {
                        ...sec,
                        orderedFields: (sec.orderedFields || []).map(of => {
                            // single
                            if (of.isSingle && of.field.uniqueIdentifier === uniqueIdentifier) {
                                return {
                                    ...of,
                                    field: {
                                        ...of.field,
                                        fileValues: [...(of.field.fileValues || []), fileData],
                                        value: of.field.label,
                                        errorMessage: '' // clear error
                                    }
                                };
                            }
                            // pair
                            if (of.isPair && Array.isArray(of.fields)) {
                                const newFields = of.fields.map(f => {
                                    if (f.uniqueIdentifier === uniqueIdentifier) {
                                        return {
                                            ...f,
                                            fileValues: [...(f.fileValues || []), fileData],
                                            value: f.label,
                                            errorMessage: ''
                                        };
                                    }
                                    return f;
                                });
                                return { ...of, fields: newFields };
                            }
                            return of;
                        })
                    };
                });

                // rebuild savedFilesBySection from full sectionFields
                this.savedFilesBySection = this.buildSavedFilesBySection(this.sectionFields);
            }

            // dispatch updated maps so parent knows current state
            this.dispatchEvent(new CustomEvent('fileschange', {
                detail: {
                    savedFilesBySection: this.savedFilesBySection,
                    savedFilesByContractor: this.savedFilesByContractor,
                    sectionFields: this.sectionFields,
                    contractorInstances: this.contractorInstances
                }
            }));
            //};
            //reader.readAsDataURL(file);
        });
        // Reset input so same file can be chosen again
        if (event.target) event.target.value = null;
    }

    // --- Remove handler ---
    handleFileRemove(event) {
        const { uniqueIdentifier, fieldName, index, contractorid } = event.detail;
        if (contractorid) {
            this.contractorInstances = (this.contractorInstances || []).map(contractor => {
                if (contractor.id !== contractorid) return contractor;
                return {
                    ...contractor,
                    formValues: { ...contractor.formValues, [uniqueIdentifier]: newFiles.length === 0 ? '' : 'File Added' },
                    fields: (contractor.fields || []).map(row => {
                        // single
                        if (row.isSingle && row.field.uniqueIdentifier === uniqueIdentifier) {
                            const newFiles = [...(row.field.fileValues || [])];
                            newFiles.splice(index, 1);

                            return {
                                ...row,
                                field: {
                                    ...row.field,
                                    fileValues: newFiles,
                                    value: newFiles.length ? row.field.label : '',
                                    errorMessage: row.field.required && newFiles.length === 0 ? `${row.field.label} is required` : ''
                                }
                            };
                        }
                        // pair
                        if (row.isPair && Array.isArray(row.fields)) {
                            const newFields = row.fields.map(f => {
                                if (f.uniqueIdentifier === uniqueIdentifier) {
                                    const newFiles = [...(f.fileValues || [])];
                                    newFiles.splice(index, 1);
                                    return {
                                        ...f,
                                        fileValues: newFiles,
                                        value: newFiles.length ? f.label : '',
                                        errorMessage: f.required && newFiles.length === 0 ? `${f.label} is required` : ''
                                    };
                                }
                                return f;
                            });
                            return { ...row, fields: newFields };
                        }
                        return row;
                    })
                };
            });
            // rebuild contractor map
            this.savedFilesByContractor = this.buildSavedFilesByContractor(this.contractorInstances);
        } else {
            this.sectionFields = (this.sectionFields || []).map(sec => {
                return {
                    ...sec,
                    orderedFields: (sec.orderedFields || []).map(of => {
                        // single
                        if (of.isSingle && of.field.uniqueIdentifier === uniqueIdentifier) {
                            const newFiles = [...(of.field.fileValues || [])];
                            newFiles.splice(index, 1);
                            if (newFiles.length === 0) {
                                this.formValues[uniqueIdentifier] = '';
                            }
                            return {
                                ...of,
                                field: {
                                    ...of.field,
                                    fileValues: newFiles,
                                    value: newFiles.length ? of.field.label : '',
                                    errorMessage: of.field.required && newFiles.length === 0 ? `${of.field.label} is required` : ''
                                }
                            };
                        }
                        // pair
                        if (of.isPair && Array.isArray(of.fields)) {
                            const newFields = of.fields.map(f => {
                                if (f.uniqueIdentifier === uniqueIdentifier) {
                                    const newFiles = [...(f.fileValues || [])];
                                    newFiles.splice(index, 1);
                                    return {
                                        ...f,
                                        fileValues: newFiles,
                                        value: newFiles.length ? f.label : '',
                                        errorMessage: f.required && newFiles.length === 0 ? `${f.label} is required` : ''
                                    };
                                }
                                return f;
                            });
                            return { ...of, fields: newFields };
                        }
                        return of;
                    })
                };
            });
            // rebuild section map
            this.savedFilesBySection = this.buildSavedFilesBySection(this.sectionFields);
        }
        // dispatch results
        this.dispatchEvent(new CustomEvent('fileschange', {
            detail: {
                savedFilesBySection: this.savedFilesBySection,
                savedFilesByContractor: this.savedFilesByContractor,
                sectionFields: this.sectionFields,
                contractorInstances: this.contractorInstances
            }
        }));
    }
    // add cache storage at class level
    notApplicableCache = {};
    handleHeaderClick(event) {
        this.template.querySelectorAll('.pill2').forEach(btn => {
            btn.classList.remove('pill2-active');
        });
        // add active class to the clicked button
        event.target.classList.add('pill2-active');
        const clickedId = event.currentTarget.dataset.id;
        this.contractorInstances = this.contractorInstances.map(ctr => {
            const isActive = ctr.id === clickedId ? !ctr.isActive : false;
            return {
                ...ctr,
                isActive,
                headerClass: `accordion-header ${isActive ? 'active' : ''}`,
                chevronClass: `chevron-icon ${isActive ? 'active' : ''}`,
                contentClass: `accordion-content ${isActive ? 'active' : ''}`
            };
        });
        this.activeSectionName = clickedId;
    }
    // Utility to normalize field values based on data type
    normalizeValue(field) {
        if (field.dataType === 'Checkbox') return false;
        if (field.dataType === 'File') return [];
        return '';
    }

    deepClone(obj) {
        return JSON.parse(JSON.stringify(obj));
    }
    isAddAnotherClicked = false;
    handleAddContractor(event) {
        this.isAddAnotherClicked = true;
        //  Validate before adding
        if (!this.validateAllInputs('Add Another Contractor')) { //&& !this.isMainContractorData) {
            console.warn('Validation failed');
            this.showError = true;
            return;
        }

        this.hasError = false;
        //  Collapse existing contractors
        this.contractorInstances = this.contractorInstances.map(c => ({ ...c, isCollapsed: true }));
        const newId = `ctr_${Date.now()}`;
        // Find the contractor section definition
        const filledSection = this.sectionFields.find(
            s =>
                s.sectionName === 'Contractor Details' ||
                s.sectionName === 'Work Permit - Contractor Details'
                || s.sectionName === 'Organizer' || s.sectionName === 'Organizer Details'
        );

        if (!filledSection) {
            console.error(' No contractor section found');
            return;
        }
        let allFields = [];
        filledSection.orderedFields.forEach(row => {
            if (row.isSingle && row.field) allFields.push(row.field);
            if (row.isPair && row.fields) allFields.push(...row.fields);
        });
        const sectionName = filledSection.sectionName;
        let fileFieldValues = {};

        if (this.savedFilesBySection && this.savedFilesBySection[sectionName]) {
            fileFieldValues = this.savedFilesBySection[sectionName];
        }
        //  Normalize and clone fields
        const processField = (f) => {
            const oldId = f.uniqueIdentifier;
            const newUniqueId = `${oldId}_${newId}`;
            const currentValue = this.formValues?.[oldId];
            const uploadedFiles = fileFieldValues?.[oldId] || f.fileValues || [];
            return {
                ...f,
                uniqueIdentifier: newUniqueId,
                value: currentValue !== undefined ? currentValue : this.normalizeValue(f),
                isDisabled:
                    f.fieldName?.includes('Not_Applicable__c') ||
                        f.label?.includes('Not Applicable')
                        ? true
                        : f.isDisabled,
                fileValues: [...uploadedFiles],
                errorMessage: '',
                // include even if invisible / controlled
                visible: f.visible ?? false
            };
        };
        //  Rebuild orderedFields for this contractor (including hidden)
        const groupedByOrder = {};
        allFields.forEach(f => {
            const order = f.displayOrder || 999;
            if (!groupedByOrder[order]) groupedByOrder[order] = [];
            groupedByOrder[order].push(f);
        });
        const savedFields = Object.keys(groupedByOrder)
            .sort((a, b) => a - b)
            .map((order, idx) => {
                const group = groupedByOrder[order];
                if (group.length === 1) {
                    return {
                        isSingle: true,
                        field: processField(group[0]),
                        rowKey: `ctr_row_${newId}_${idx}`
                    };
                }
                return {
                    isPair: true,
                    fields: group.map(processField),
                    rowKey: `ctr_row_${newId}_${idx}`
                };
            });

        // 7️Extract header info
        let customerName = '';
        let tradeLicense = '';
        savedFields.forEach(row => {
            const fields = row.fields || [row.field];
            fields.forEach(f => {
                if (f.fieldName === 'Name' && f.label === 'Contractor Name') customerName = f.value || 'Unknown';
                if (f.fieldName === 'RegistrationNumber__c' && f.label === 'Trade License No') tradeLicense = f.value || '';
            });
        });

        const accordionName = `${customerName || 'Customer'} - ${tradeLicense || 'License'}`;

        // 8️ Build formValues
        const sectionFormValues = {};
        savedFields.forEach(row => {
            const fields = row.fields || [row.field];
            fields.forEach(f => {
                sectionFormValues[f.uniqueIdentifier] = f.value;
            });
        });

        // 9️ Build contractor instance
        const savedInstance = {
            id: newId,
            isCollapsed: true,
            fields: savedFields,
            formValues: sectionFormValues,
            accordionName,
            headerText: accordionName,
            iconSrc: this.icone12image,
            isActive: false,
            headerClass: 'accordion-header',
            chevronClass: 'chevron-icon',
            contentClass: 'accordion-content',
            isMainContractorData: this.isMainContractorData
        };

        // Add to list
        this.contractorInstances = [...this.contractorInstances, savedInstance];
        console.log('contractorInstances', JSON.stringify(this.contractorInstances))
        // 11 Reset Contractor section form
        this.sectionFields = this.sectionFields.map(sec => {
            if (
                sec.sectionName === 'Contractor Details' ||
                sec.sectionName === 'Work Permit - Contractor Details'
                || sec.sectionName === 'Organizer' || sec.sectionName === 'Organizer Details'
            ) {
                const newOrdered = sec.orderedFields.map(row => {
                    const shouldNotHideField = (field) => {
                        const hasOneContractorMinimum = (this.allValidations || []).some(
                            v => v.validationRule === 'OneContractorMinimum'
                        );
                        const contractorCount = this.contractorInstances?.length || 0;

                        const isNotApplicableField =
                            field.fieldName === 'RETL_Not_Applicable__c' ||
                            field.fieldName?.includes('Not_Applicable') ||
                            field.fieldName?.includes('NotApplicable');

                        return hasOneContractorMinimum && contractorCount >= 1 && isNotApplicableField;
                    };
                    const resetField = (f) => ({
                        ...f,
                        value: this.normalizeValue(f),
                        fileValues: [],
                        errorMessage: '',
                        visible: shouldNotHideField(f) ? true : f.visible
                    });
                    if (row.isSingle && row.field) {
                        const fname = row.field.uniqueIdentifier;
                        this.formValues[fname] = this.normalizeValue(row.field);
                        row.field = {
                            ...row.field,
                            isDisabled: false
                        };
                        // if (row.fld.fieldName === 'Make_Contractor_as_Responsible_Person__c') {
                        //     row.field = {
                        //         ...row.field,
                        //         value: false
                        //     };
                        // }
                        return { ...row, field: resetField(row.field) };
                    }

                    if (row.isPair && row.fields) {
                        return {
                            ...row,
                            fields: row.fields.map(f => {
                                this.formValues[f.uniqueIdentifier] = this.normalizeValue(f);
                                const updatedField = { ...f, isDisable: false };
                                return resetField(updatedField);
                            })
                        };
                    }
                    return row;
                });
                return { ...sec, orderedFields: newOrdered };
            }
            return sec;
        });
        this.formValues = { ...this.formValues };
        this.addedContracts = true;
        this.activeSectionName = newId;
        if (this.mainContractorExistingData && this.isMainContractorData) {
            this.isMainContractorData = false;
        }
    }

    handleRemoveContractor(event) {
        event.stopPropagation();
        const id = event.currentTarget.dataset.id;
        // remove contractor instance
        const removed = this.contractorInstances.find(c => c.id === id);
        this.contractorInstances = this.contractorInstances.filter(c => c.id !== id);
        // clear its values from formValues
        if (removed) {
            removed.fields.forEach(row => {
                if (row.isSingle && row.field) {
                    delete this.formValues[row.field.uniqueIdentifier];
                }
                if (row.isPair) {
                    row.fields.forEach(f => delete this.formValues[f.uniqueIdentifier]);
                }
            });
        }
        // adjust activeSectionName
        if (this.activeSectionName === id) {
            this.activeSectionName = this.contractorInstances.length
                ? this.contractorInstances[this.contractorInstances.length - 1].id
                : null;
        }
    }

    isCountryOptionsLoaded = false;
    contractorButtonLabel = 'Add Another Contractor';
    get currentStepSections() {
        this.isCountryOptionsLoaded = false;
        let filtered = this.sectionFields.filter(sec => sec.stepNumber === this.currentStep);
        const section = filtered[0]?.sectionName;
        if (section === 'Contractor Details' || section === 'Work Permit - Contractor Details') {
            this.isContractor = true;
            this.contractorButtonLabel = 'Add Another Contractor';

        }
        else if (section === 'Organizer' || section === 'Organizer Details') {
            this.isContractor = true;
            this.contractorButtonLabel = 'Add Another Organizer';
        } else {
            this.isContractor = false;
        }

        this.addedContracts = this.contractorInstances && this.isContractor ? true : false;
        if (filtered.length) {
            this.dispatchEvent(
                new CustomEvent('dataloaded', { detail: filtered[0].stepTitle })
            );
        }
        if (filtered.length && !this.isCountryOptionsLoaded) {
            const hasNationalityField = filtered.some(
                sec => sec.orderedFields?.some(
                    f => f.field?.dataType === 'Dropdown' && f.field?.label.includes('Nationality')
                )
            );
            if (hasNationalityField) {
                filtered = this.loadCountryPicklist(filtered);
            }
        }
        return filtered;
    }

    loadCountryPicklist(filtered) {
        // Step 1: if we have not yet fetched the list, do it once
        if (!this.nationalityOptions || this.nationalityOptions.length === 0) {
            this.isCountryOptionsLoaded = true; // prevent parallel calls

            getCountryPicklistValues()
                .then(data => {
                    //this.nationalityOptions = data.map(v => ({ label: v, value: v }));
                    // After fetching, push into every matching field
                    this.nationalityOptions = [...data];
                    filtered = this.assignNationalityOptions(filtered);
                })
                .catch(error => {
                    this.isCountryOptionsLoaded = false; // allow retry on error
                    console.error('Error fetching countries', error);
                });
        } else {
            // Step 2: already cached → just assign to the fields
            filtered = this.assignNationalityOptions(filtered);
        }
        return filtered;
    }

    // Assign the cached nationality options to every dropdown field that needs them.
    assignNationalityOptions(filtered) {
        filtered.forEach(sec => {
            sec.orderedFields?.forEach(f => {
                if (f.field?.dataType === 'Dropdown') {
                    f.field.dropdownOptions = this.nationalityOptions;
                }
            });
        });
        return filtered;
    }

    @api handleNext(event) {
        let buttonLabel = event.target.label;
        let validateResult = true;
        if (!this.isContractor || (this.isContractor)) {//& !this.isMainContractorData)) {
            validateResult = this.validateAllInputs(buttonLabel);
        }

        if (!validateResult) {
            console.warn('Validation failed', validateResult);
            return false;
        }
        this.hasError = false;
        return true;
    }

    checkContractor(event) {
        if (this.contractorInstances && this.contractorInstances.length > 0) {
            return true; // okay
        }
        else {
            event.preventDefault();
            return false;
        }
    }

    validateAllInputs(buttonLabel) {
        let allValid = true;
        if (buttonLabel === 'Add Another Contractor') {

        }
        else {


            // 1Check globally if any Responsible Person exists (for submit only)
            const isAnyResponsibleChecked = () => {
                const foundInForm = Object.keys(this.formValues || {}).some(key => {
                    return key.includes('Make_Contractor_as_Responsible_Person__c') && this.formValues[key] === true;
                });
                const foundInContractors = (this.contractorInstances || []).some(contractor => {
                    return contractor.fields?.some(row => {
                        const fields = row.fields || (row.field ? [row.field] : []);
                        return fields.some(f =>
                            f.fieldName?.includes('Make_Contractor_as_Responsible_Person__c') &&
                            (f.value === true || f.value === 'true')
                        );
                    });
                });
                return foundInForm || foundInContractors;
            };
            // 2Check if specific contractor is responsible
            const isContractorResponsible = (contractor) => {
                return contractor.fields?.some(row => {
                    const fields = row.fields || (row.field ? [row.field] : []);
                    return fields.some(f =>
                        f.fieldName?.includes('Make_Contractor_as_Responsible_Person__c') &&
                        (f.value === true || f.value === 'true')
                    );
                });
            };
            // 3️Generic field validator helper
            const shouldValidateField = (f, contextIsResponsible) => {
                // If field is controlled by "Make_Contractor_as_Responsible_Person__c"
                const isControlledByResponsible = (f.controlledBy || []).includes('Make_Contractor_as_Responsible_Person__c');
                // Only validate if the controlling checkbox (in this context) is true
                if (isControlledByResponsible && !contextIsResponsible) {
                    return false;
                }
                return true;
            };

            this.errorText = '';
            const hasOneContractorMinimum = (this.allValidations || []).some(v => v.validationRule === 'OneContractorMinimum');
            //  1. Contractor validation (Submit only)
            if (this.isContractor === true && hasOneContractorMinimum) {
                const contractorCount = this.contractorInstances?.length || 0;
                const responsibleSelected = isAnyResponsibleChecked();

                if (contractorCount === 0 && !responsibleSelected && this.resposiblePersonType !== 'Organizer') {
                    this.errorText = 'Please add ' + this.resposiblePersonType + ' details and responsible person details';
                    console.log('errorText', this.errorText)
                    return false;
                }
                if (contractorCount >= 1 && !responsibleSelected && this.resposiblePersonType !== 'Organizer') {
                    this.errorText = 'Please select at least one contractor as responsible person';
                    console.log('errorText', this.errorText)
                    return false;
                }
                this.errorText = '';
            }
            //  2. Validate only current step sections
            const currentStepSections = (this.sectionFields || []).filter(
                sec => sec.stepNumber === this.currentStep
            );
            const updatedSections = (this.sectionFields || []).map(sec => {
                if (sec.stepNumber !== this.currentStep) return sec;
                // Determine if *this* section's controlling checkbox is true
                const sectionIsResponsible = Object.keys(this.formValues || {}).some(key =>
                    key.includes('Make Contractor as Responsible Person') && this.formValues[key] === true
                );
                return {
                    ...sec,
                    orderedFields: sec.orderedFields.map(row => {
                        const fields = row.fields || (row.field ? [row.field] : []);
                        const updatedFields = fields.map(f => {
                            if (!shouldValidateField(f, sectionIsResponsible)) {
                                return { ...f, errorMessage: '' }; // Skip
                            }
                            if (this.isMainContractorData && this.isContractor) {

                            }
                            else if (f.dataType === 'File' && f.required) {
                                if (!f.fileValues || f.fileValues.length === 0) {
                                    allValid = false;
                                    return { ...f, errorMessage: `${f.label} is required` };
                                } else {
                                    return { ...f, errorMessage: '' };
                                }
                            }
                            return f;
                        });

                        if (row.isPair) return { ...row, fields: updatedFields };
                        if (row.isSingle) return { ...row, field: updatedFields[0] };
                        return row;
                    })
                };
            });
            console.log('allValid2', allValid)

            this.sectionFields = [...updatedSections];
            //  3. Validate contractorInstances
            this.contractorInstances = (this.contractorInstances || []).map(contractor => {
                const contractorIsResponsible = isContractorResponsible(contractor);
                return {
                    ...contractor,
                    fields: contractor.fields.map(row => {
                        const fields = row.fields || (row.field ? [row.field] : []);
                        const updatedFields = fields.map(f => {
                            if (!shouldValidateField(f, contractorIsResponsible)) {
                                return { ...f, errorMessage: '' }; // skip
                            }

                            if (f.dataType === 'File' && f.required && !f.isMainContractorField) {
                                if (!f.fileValues || f.fileValues.length === 0) {
                                    allValid = false;
                                    return { ...f, errorMessage: `${f.label} is required` };
                                } else {
                                    return { ...f, errorMessage: '' };
                                }
                            }

                            return f;
                        });

                        if (row.isPair) return { ...row, fields: updatedFields };
                        if (row.isSingle) return { ...row, field: updatedFields[0] };
                        return row;
                    })
                };
            });

            this.sectionFields = [...this.sectionFields];
            this.contractorInstances = [...this.contractorInstances];
            console.log('allValid 1', allValid)
            // if (this.isMainContractorData && this.isContractor) {
            //     return allValid;
            // }
        }
        //  4. Validate other visible fields (child components)

        const children = this.template.querySelectorAll('c-retl-_-tenant-dynamic-field-rendering');
        children.forEach(cmp => {
            if (!cmp.validate()) {
                allValid = false;
            }
        });
        console.log('allValid', allValid)
        return allValid;


    }

    @api submitCallFromParent() {
        this.handleSubmit();
    }

    async handleSubmit() {
        try {
            const allFieldValues = this.getFieldValues();
            let groupedFieldValues = {};
            Object.keys(allFieldValues).forEach(key => {
                const { value, sObjectApiName } = allFieldValues[key] || {};
                if (!sObjectApiName) {
                    console.warn('Missing sObjectApiName for field:', key, allFieldValues[key]);
                }
                if (!groupedFieldValues[sObjectApiName]) {
                    groupedFieldValues[sObjectApiName] = {};
                }
                groupedFieldValues[sObjectApiName][key] = value;
            });
            let contractorsArr = [];
            (this.contractorInstances || []).forEach(instance => {
                if (!instance.fields) {
                    console.warn(' Contractor instance missing fields:', instance);
                    return;
                }
                const contractorObj = this.buildContractorPayload(instance, instance.formValues);
                if (contractorObj) contractorsArr.push(contractorObj);
            });
            const contractorSection = (this.sectionFields || []).find(
                s => s.sectionName === 'Contractor Details' || s.sectionName === 'Work Permit - Contractor Details' || s.sectionName === 'Organizer' || s.sectionName === 'Organizer Details'
            );
            if (contractorSection) {
                const contractorObj = this.buildContractorPayload(contractorSection, this.formValues);
                if (contractorObj) contractorsArr.push(contractorObj);
            }
            const allDocuments = this.collectFilesFromSectionFields();
            // 3. Build final payload for Apex
            let wrapperPayload = {
                Case1: groupedFieldValues['Case'],
                AdditionalInfo: groupedFieldValues['RETL_SR_Additional_Info__c'],
                Contractors: contractorsArr
            };
            // 4. Call Apex
            const result = await createRecord({
                groupedFieldValuesJson: JSON.stringify(wrapperPayload),
                category: this.selectedCategory,
                subCategory: this.selectedSubCategory,
                serviceType: this.selectedServiceType,
                orderId: this.orderId,
                contactId: this.contactId,
                storeName: this.storeName
            });
            let files = [];
            files.push(allDocuments);
            //allDocuments[i].parentId = result.newCase.Id;
            const response = await createFileRecord({
                filesData: JSON.stringify(allDocuments),
                parentId: result.newCase.Id,
                caseCommentId: null
            });
            this.isCaseCreated = true;
            this.dispatchEvent(new CustomEvent('casecreated', {
                detail: {
                    caseCreated: true,
                    caseId: result.newCase.Id,
                    caseNumber: result.newCase.CaseNumber,
                    caseComments: result.newCase.CaseComments__c,
                    subject: result.newCase.Subject,
                    description: result.newCase.Description
                }
            }));
        } catch (error) {
            if (error && error.body && error.body.message) {
                console.error('Apex Message:', error.body.message);
            }
            this.isLoading = false;
            this.dispatchEvent(new CustomEvent('submitfailed', {
                detail: { message: 'Fail' },
                bubbles: true,
                composed: true
            }));
        }
    }

    buildContractorPayload(source, formValues) {
        let contractorObj = { Account: {}, Contact: {} };

        // Support both instance.fields and section.orderedFields
        const rows = source.fields || source.orderedFields || [];

        rows.forEach(row => {
            console.log('row', JSON.stringify(row));
            // ---- Single field ----
            if (row.isSingle && row.field) {
                const f = row.field;
                const val = formValues?.[f.uniqueIdentifier] ?? f.value ?? '';

                if (val && val !== '') {
                    if (f.sfObjectName === 'Account') {
                        contractorObj.Account[f.fieldName] = val;
                    } else if (f.sfObjectName === 'Contact') {
                        contractorObj.Contact[f.fieldName] = val;
                    }
                    if (f.fieldName === 'Make_Contractor_as_Responsible_Person__c') {
                        contractorObj.isResponsible = val === true || val === 'true';
                }
            }

            }
            // ---- Paired fields ----
            else if (row.isPair && Array.isArray(row.fields)) {
                row.fields.forEach(f => {
                    const val = formValues?.[f.uniqueIdentifier] ?? f.value ?? '';
                    if (val && val !== '') {
                        if (f.sfObjectName === 'Account') {
                            contractorObj.Account[f.fieldName] = val;
                        } else if (f.sfObjectName === 'Contact') {
                            contractorObj.Contact[f.fieldName] = val;
                        }
                        if (f.fieldName === 'Make_Contractor_as_Responsible_Person__c') {
                            contractorObj.isResponsible = val === true || val === 'true';
                        }
                    }
                });
            }
        });

        // Clean empty objects
        if (Object.keys(contractorObj.Account).length === 0) {
            delete contractorObj.Account;
        }
        if (Object.keys(contractorObj.Contact).length === 0) {
            delete contractorObj.Contact;
        }

        return (contractorObj.Account || contractorObj.Contact) ? contractorObj : null;
    }
    collectFilesFromSectionFields() {
        const docsMap = new Map();
        // Files from main sections
        let filesList = [];
        (this.sectionFields || []).forEach(sec => {
            (sec.orderedFields || []).forEach(row => {
                const collect = (fld) => {
                    if (fld.dataType === 'File') {
                        (fld.fileValues || []).forEach(f => {
                            const docType = f.documentType || fld.label || 'General';
                            if (!docsMap.has(docType)) {
                                docsMap.set(docType, []);
                            }
                            docsMap.get(docType).push({
                                contentVersionId: f.contentVersionId
                                // fileName: f.filename,
                                // base64: f.base64
                            });
                            // let docMap = {
                            //     documentType: docType,
                            //     contentVersions: [{
                            //         fileName: f.filename,
                            //         base64: f.base64
                            //     }]
                            // };
                            // filesList.push(docMap);
                        });
                    }
                };

                if (row.isSingle && row.field) collect(row.field);
                if (row.isPair && Array.isArray(row.fields)) row.fields.forEach(collect);
            });
        });
        //  Files from contractor instances
        (this.contractorInstances || []).forEach(instance => {
            (instance.fields || []).forEach(row => {
                const collect = (fld) => {
                    if (fld.dataType === 'File') {
                        (fld.fileValues || []).forEach(f => {
                            const docType = f.documentType || fld.label || 'Contractor Document';
                            if (!docsMap.has(docType)) {
                                docsMap.set(docType, []);
                            }
                            docsMap.get(docType).push({
                                contentVersionId: f.contentVersionId
                                // fileName: f.filename,
                                // base64: f.base64
                            });
                            // let docMap = {
                            //     documentType: docType,
                            //     contentVersions: [{
                            //         fileName: f.filename,
                            //         base64: f.base64
                            //     }]
                            // };
                            // filesList.push(docMap);
                        });
                    }
                };

                if (row.isSingle && row.field) collect(row.field);
                if (row.isPair && Array.isArray(row.fields)) row.fields.forEach(collect);
            });
        });
        return Array.from(docsMap, ([documentType, contentVersions]) => ({
            documentType,
            contentVersions
        }));
    }

    getFieldValues() {
        const values = {};

        this.sectionFields.forEach(section => {
            // ߔ須andle button fields
            if (section.buttonFields && section.buttonFields.length) {
                section.buttonFields.forEach(f => {
                    if (f.dataType !== 'File') {
                        values[f.fieldName] = {
                            value: this.formValues[f.uniqueIdentifier] ?? f.value ?? '',
                            sObjectApiName: f.sfObjectName || 'Case'
                        };
                    }
                });
            }

            //Handle orderedFields (single + pair)
            section.orderedFields.forEach(item => {
                if (item.isSingle) {
                    const f = item.field;
                    if (f.dataType !== 'File') {
                        values[f.fieldName] = {
                            value: this.formValues[f.uniqueIdentifier] ?? f.value ?? '',
                            sObjectApiName: f.sfObjectName || 'Case'
                        };
                    }
                } else if (item.isPair) {
                    item.fields.forEach(f => {
                        if (f.dataType !== 'File') {   //skip file fields
                            values[f.fieldName] = {
                                value: this.formValues[f.uniqueIdentifier] ?? f.value ?? '',
                                sObjectApiName: f.sfObjectName || 'Case'
                            };
                        }
                    });
                }
            });
        });
        return values;
    }

    get pairClasses() {
        // Example: dynamically append the aligner class
        return `pair-container ${this.hasError ? 'slds-grid slds-m-around_x-small slds-wrap pair-container pair-container-top-aligner' : 'slds-grid slds-m-around_x-small slds-wrap pair-container pair-container-bottom-aligner'}`;
    }

    handleErrorState(event) {
        this.hasError = event.detail.hasError;
    }
}