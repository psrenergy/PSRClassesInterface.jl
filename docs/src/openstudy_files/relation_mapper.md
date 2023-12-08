# Relation Mapper

If you have already checked the [PMD manual](./pmd.md), you know that a PMD file can define relations between models.
When these relations are parsed, they are stored in a Julia dictionary, the Relation Mapper.

## Relation Mapper JSON file

However, it is also possible to fill the Relation Mapper with a JSON file, that follows the same structure as `OpenStudy`'s dictionary for relations.

In the example below, we have a Relation Mapper file with the following information:
- The model `CustomModel` has two relations defined, one with `SecondCollection` and another with `ThirdCollection`.
    - The relation with `SecondCollection` is a `1_to_1` relation, and the parameter is called `system`. 
    - The relation with `ThirdCollection` is a `1_to_N` relation, and the parameter is called `station`. 
- The model `SecondCollection` has two relations with `FourthCollection`.
    - The first relation with `FourthCollection` is a `FROM` relation, and the parameter is called `no1`.
    - The second relation with `FourthCollection` is a `TO` relation, and the parameter is called `no2`.

!!! info "💭 Reminder"
    The relation parameter stores the `reference_id` from the element of the Target Collection. See [PMD manual](./pmd.md)


```json
{
    "CustomCollection": {
        "SecondCollection": {
            "system": {
                "is_vector": false,
                "type": "1_TO_1"
            }
        },
        "ThirdCollection": {
            "station": {
                "is_vector": true,
                "type": "1_TO_N"
            }
        }
    },
    "SecondCollection": {
        "FourthCollection": {
            "no1": {
                "is_vector": false,
                "type": "FROM"
            },
            "no2": {
                "is_vector": false,
                "type": "TO"
            }
        }
    }
}
```
