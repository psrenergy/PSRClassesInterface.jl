# Model Template

The models defined in a [PMD](./pmd.md) file are mapped to collections in an `OpenStudy` instance with a Model Template file.

A Model Template is a JSON file with the following syntax.


```json
[
    {
        "classname": "CustomCollection",
        "models": [
            "Custom_Model_v1"
        ]
    },
    {
        "classname": "SecondCollection",
        "models": [
            "Another_Custom_Model_v1"
        ]
    }
]
```

Inside `classname` you define the name of the collection that represents a model stated in `models`.
This model is defined in a PMD file.

To learn more about how to use custom PMD files with Model Templates, see the [Customizing a Study](../examples/custom_study.md) example.