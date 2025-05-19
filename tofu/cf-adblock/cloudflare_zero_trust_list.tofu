locals {
  # Directory where the external script (run by GitHub Actions before tofu plan)
  # outputs the chunked domain files. This directory should be gitignored.
  # Example: <module_path>/processed_adblock_chunks/
  chunk_files_output_dir  = "${path.module}/processed_adblock_chunks"
  chunk_file_name_pattern = "adblock_chunk_*.txt" # Pattern the script uses for output files

  # Discover all chunk files created by the script.
  # fileset() returns a sorted list of file paths relative to chunk_files_output_dir.
  discovered_chunk_filenames = fileset(local.chunk_files_output_dir, local.chunk_file_name_pattern)

  # Step 1: Create a map of filenames to their raw (trimmed) content.
  chunk_file_contents = {
    for filename in local.discovered_chunk_filenames :
    filename => trimspace(file("${local.chunk_files_output_dir}/${filename}"))
  }

  # Step 2: Create the final map, processing the content from the map above.
  list_definitions_from_files = {
    for filename, content_str in local.chunk_file_contents : # Iterate over the pre-processed content
    filename => {
      # raw_content_for_this_file = content_str // Just for clarity, same as content_str
      domains_in_chunk = [for d in split("\n", content_str) : d if d != ""]
    }
  }

  # For the 'block_ads' policy that uses these lists:
  # Collect all IDs from the cloudflare_zero_trust_list resources that will be created.
}

resource "cloudflare_zero_trust_list" "adblock_domain_lists" {
  account_id = var.cloudflare_secondary_account_id

  # for_each iterates over the map of discovered chunk filenames and their processed domains.
  # each.key is the filename (e.g., "adblock_chunk_000.txt").
  # each.value is the map { file_content = "...", domains_in_chunk = [...] }.
  for_each = local.list_definitions_from_files # Changed to new local variable name

  # Create a Cloudflare list name derived from the chunk filename for stability and traceability.
  # Example: "adblock_chunk_000.txt" becomes "ad-list-adblock-chunk-000".
  name        = "ad-list-${replace(replace(each.key, ".txt", ""), "_", "-")}"
  type        = "DOMAIN"
  items       = [for domain_str in each.value.domains_in_chunk : { value = domain_str }] # Changed to use domains_in_chunk
  description = "Adblock list. Source chunk file: ${each.key}. Managed by Terraform."
}
