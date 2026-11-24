extends Node

# Neue Jobs kommen hinten an. Gesucht wird immer von vorne.
var jobs: Array[JobData] = []


func post_job(job: JobData) -> bool:
	if job == null or jobs.has(job):
		return false

	if job.status != &"open" or job.assigned_to != null:
		return false

	jobs.append(job)
	return true


func get_available_jobs(accepted_types: Array[StringName]) -> Array[JobData]:
	var available_jobs: Array[JobData] = []

	for job in jobs:
		if job.status == &"open":
			if accepted_types.is_empty() or accepted_types.has(job.job_type):
				available_jobs.append(job)

	return available_jobs


func take_job(accepted_types: Array[StringName], worker: Node) -> JobData:
	if not is_instance_valid(worker):
		return null

	# Wiederholte Anfragen liefern den bereits angenommenen Job.
	for job in jobs:
		if job.status == &"reserved" and job.assigned_to == worker:
			return job

	for job in jobs:
		if job.status == &"open" and accepted_types.has(job.job_type):
			job.assigned_to = worker
			job.status = &"reserved"
			return job

	return null


func complete_job(job: JobData, worker: Node) -> bool:
	if job == null or not jobs.has(job) or not is_instance_valid(worker):
		return false

	if job.status != &"reserved" or job.assigned_to != worker:
		return false

	job.status = &"completed"
	job.assigned_to = null
	jobs.erase(job)
	return true


func release_job(job: JobData, worker: Node) -> bool:
	if job == null or not jobs.has(job) or not is_instance_valid(worker):
		return false

	if job.status != &"reserved" or job.assigned_to != worker:
		return false

	job.assigned_to = null
	job.status = &"open"
	return true
