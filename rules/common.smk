
def _get_region_name_by_wildcards(wildcards):
    return config["region_name_by_region"][wildcards.region]

def _get_query_argument_by_wildcards(wildcards):
    if wildcards.region == "global":
        return ""
    else:
        region_name = _get_region_name_by_wildcards(wildcards)
        return f"--query \"region == '{region_name}'\""
