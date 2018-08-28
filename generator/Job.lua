local Job = {}
Job.__index = Job

function Job.new(func, timeoutMs, name)
	local self = {
		timeout = timeoutMs / 1000,
		name = name,
	}
	setmetatable(self, Job)

	self.thread = coroutine.create(function()
		func(self)
	end)

	return self
end

function Job:breath(taskName)
	if self.taskName then
		debug.profileend()
	end
	self.taskName = taskName
	if self.taskName then
		debug.profilebegin(taskName)
	end
	if tick() - self.tickStart > self.budget then
		coroutine.yield()
	end
end

function Job:expired()
	return coroutine.status(self.thread) == "dead" or tick() - self.jobStart > self.timeout
end

function Job:tick(budgetMs)
	self.budget = budgetMs / 1000
	self.tickStart = tick()
	if not self.jobStart then
		self.jobStart = self.tickStart
	end

	debug.profilebegin("Job "..self.name)
	if self.taskName then
		debug.profilebegin(self.taskName)
	end
	local ok, err = coroutine.resume(self.thread)
	if not ok then
		warn(err)
	end
	if self.taskName then
		debug.profileend()
	end
	debug.profileend()
end

return Job
