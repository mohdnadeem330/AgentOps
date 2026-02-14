/**
  * Columns definition
  * :: used in examples
  */
   export const EXAMPLES_COLUMNS_DEFINITION_BASIC = [
    {
        type: 'text',
        fieldName: 'column1',
        label: 'Title',
        cellAttributes: { alignment: `left`,class: 'title-cell' /*important for reponsive */}
        // initialWidth: 300,
    },
    {
        type: 'text',
        fieldName: 'column2',
        label: 'First Name',
        cellAttributes: { class: 'first-name-cell' /*important for reponsive */ }
    },
    {
        type: 'text',
        fieldName: 'column3',
        label: 'Last Name',
        cellAttributes: { class: 'last-name-cell' /*important for reponsive */ }
    },
    {
        type: 'text',
        fieldName: 'column4',
        label: 'Email',
        cellAttributes: { class: 'email-cell' /*important for reponsive */ }
    },
    {
        type: 'text',
        fieldName: 'column5',
        label: 'Mobile',
        cellAttributes: { class: 'mobile-cell' /*important for reponsive */ }
    },
    {
        type: 'text',
        fieldName: 'column6',
        label: 'Country',
        cellAttributes: { class: 'country-cell' /*important for reponsive */ }
    },{
        type: 'text',
        fieldName: 'column7',
        label: '',
        initialWidth: 10,
        cellAttributes: { class:'column-id' /*important for reponsive */}
    }
];


export const EXAMPLES_DATA_BASIC = [
    {
        column1: 'title',
        column2: 'Rewis Inc',
        column3: "test",
        column4: " sdfsdf",
        column5: '837-555-0100',
        column6: 'ABCD',
        column7:1
    },

    {
        column1: 'title2',
        column2: 'Rewis Inc',
        column3: "test",
        column4: " sdfsdf",
        column5: '837-555-0100',
        column6: 'ABCD',
        column7:2,
    
        
        _children: [
            {
        column1: 'Project: Mamsha1',
        column2: '',
        column3: "Unity Type: 2BHK",
        column4: "",
        column5: 'Created Date & Time: 15.30-22/01/2022',
        column6: 'Promotion: Q4 Summer Promo Summer 2021',
        column7:111
      
            },

            {
        column1: 'Project: Mayan1',
        column2: '',
        column3: "Unity Type: 2BHK + M",
        column4: "",
        column5: 'Created Date & Time: 15.00-22/01/2022',
        column6: 'Promotion: Q4 Summer Promo Summer 2021',
        column7:222
     
            }, {
                column1: 'Project: Mayan1',
                column2: '',
                column3: "Unity Type: 2BHK + M",
                column4: "",
                column5: 'Created Date & Time: 15.00-22/01/2022',
                column6: 'Promotion: Q4 Summer Promo Summer 2021',
                column7:999
             
                    }, {
                        column1: 'Project: Mayan1',
                        column2: '',
                        column3: "Unity Type: 2BHK + M",
                        column4: "",
                        column5: 'Created Date & Time: 15.00-22/01/2022',
                        column6: 'Promotion: Q4 Summer Promo Summer 2021',
                        column7:101010
                     
                            }
        ],
    },

    {
        column1: 'title5',
        column2: 'Rewis Inc',
        column3: "test",
        column4: " sdfsdf",
        column5: '837-555-0100',
        column6: 'ABCD',
        column7:3,
        _children: [
            {
                column1: 'Project: Mayan2',
                column2: '',
                column3: "Unity Type: 2BHK + M",
                column4: "",
                column5: 'Created Date & Time: 15.00-22/01/2022',
                column6: 'Promotion: Q4 Summer Promo Summer 2021',
                column7:333
                    
            },

            {
        column1: 'Project: Mayan21',
        column2: '',
        column3: "Unity Type: 2BHK + M",
        column4: "",
        column5: 'Created Date & Time: 15.00-22/01/2022',
        column6: 'Promotion: Q4 Summer Promo Summer 2021',
        column7:444
            },

            {
        column1: 'ASDFASDF ASDF 21',
        column2: '',
        column3: "Unity Type: 2BHK + M",
        column4: "",
        column5: 'Created Date & Time: 15.00-22/01/2022',
        column6: 'Promotion: Q4 Summer Promo Summer 2021',
        column7:555
            },

            {
        column1: 'datadatadata',
        column2: '',
        column3: "Unity Type: 2BHK + M",
        column4: "",
        column5: 'Created Date & Time: 15.00-22/01/2022',
        column6: 'Promotion: Q4 Summer Promo Summer 2021',
        column7:666
            }
        ],
    },

    {
        column1: 'title7',
        column2: 'Rewis Inc',
        column3: "test",
        column4: " sdfsdf",
        column5: '837-555-0100',
        column6: 'ABCD',
        column7:4,

        _children: [
            {
                column1: 'Project: Mayan',
                column2: '',
                column3: "Unity Type: 2BHK + M",
                column4: "",
                column5: 'Created Date & Time: 15.00-22/01/2022',
                column6: 'Promotion: Q4 Summer Promo Summer 2021',
                column7:1
  
            },
        ],
    },
];